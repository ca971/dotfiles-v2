--- @module "lib.platform""
--- @description Comprehensive platform and environment detection.
--- Detects OS family, distribution, architecture, WSL, containers (Docker,
--- Podman, Kubernetes), virtualization (Proxmox, VPS), and remote sessions
--- (SSH, Mosh). Results are cached for performance.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")

--- @class PlatformInfo
--- @field os string Operating system family: "linux"|"macos"|"windows"|"bsd"|"unknown"
--- @field os_release string Detailed OS version string
--- @field arch string CPU architecture: "x86_64"|"aarch64"|"arm"|"unknown"
--- @field is_wsl boolean Running inside WSL
--- @field wsl_version number|nil WSL version (1 or 2) if applicable
--- @field is_ssh boolean Connected via SSH
--- @field is_mosh boolean Connected via Mosh
--- @field is_remote boolean Any remote session (SSH or Mosh)
--- @field is_docker boolean Running inside Docker container
--- @field is_podman boolean Running inside Podman container
--- @field is_container boolean Running inside any container
--- @field is_kubernetes boolean Running inside Kubernetes pod
--- @field is_proxmox boolean Running on Proxmox VE
--- @field is_opnsense boolean Running on OPNsense
--- @field is_vps boolean Likely running on a VPS/cloud instance
--- @field hostname string System hostname
--- @field home string Home directory path
--- @field shell string Current shell path

--- @class Platform
--- @field _info PlatformInfo|nil Cached platform information
local Platform = Class.new("Platform")

--- @type PlatformInfo|nil
--- Module-level cache (singleton pattern).
local _cached_info = nil

---------------------------------------------------------------------------
-- Internal detection helpers
---------------------------------------------------------------------------

--- Execute a shell command and return trimmed output.
--- @param cmd string The command to execute
--- @return string|nil output The trimmed output or nil on failure
local function exec(cmd)
  local ok, wezterm = pcall(require, "wezterm")

  -- Prefer io.popen for broader compatibility
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result then
    result = result:match("^%s*(.-)%s*$")
    if #result > 0 then
      return result
    end
  end

  return nil
end

--- Check if a file exists (lightweight check).
--- @param filepath string The file path
--- @return boolean exists True if readable
local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

--- Read first line of a file.
--- @param filepath string The file path
--- @return string|nil content First line or nil
local function read_file_line(filepath)
  local f = io.open(filepath, "r")
  if not f then
    return nil
  end
  local line = f:read("*l")
  f:close()
  return line
end

--- Detect the OS family.
--- @return string os_family The OS family name
--- @return string os_release Detailed OS info
local function detect_os()
  local sep = package.config:sub(1, 1)

  if sep == "\\" then
    local ver = exec("ver") or "Windows"
    return "windows", ver
  end

  -- Check uname
  local uname = exec("uname -s")
  if not uname then
    return "unknown", "unknown"
  end

  local uname_lower = uname:lower()

  if uname_lower == "darwin" then
    local version = exec("sw_vers -productVersion") or ""
    return "macos", "macOS " .. version
  end

  if uname_lower == "linux" then
    -- Try to get distro info
    local release = ""
    if file_exists("/etc/os-release") then
      local f = io.open("/etc/os-release", "r")
      if f then
        local content = f:read("*a")
        f:close()
        local pretty = content:match('PRETTY_NAME="([^"]+)"')
        release = pretty or "Linux"
      end
    else
      release = exec("uname -r") or "Linux"
    end
    return "linux", release
  end

  if uname_lower:match("bsd") or uname_lower == "freebsd" or uname_lower == "openbsd" then
    local version = exec("uname -r") or ""
    return "bsd", uname .. " " .. version
  end

  return "unknown", uname or "unknown"
end

--- Detect CPU architecture.
--- @return string arch The architecture string
local function detect_arch()
  local arch = exec("uname -m")
  if not arch then
    -- Windows fallback
    local proc_arch = os.getenv("PROCESSOR_ARCHITECTURE")
    if proc_arch then
      if proc_arch == "AMD64" then
        return "x86_64"
      end
      return proc_arch:lower()
    end
    return "unknown"
  end

  local normalized = arch:lower()
  if normalized == "x86_64" or normalized == "amd64" then
    return "x86_64"
  elseif normalized == "aarch64" or normalized == "arm64" then
    return "aarch64"
  elseif normalized:match("^arm") then
    return "arm"
  end

  return normalized
end

--- Detect if running under WSL.
--- @return boolean is_wsl
--- @return number|nil wsl_version
local function detect_wsl()
  -- Method 1: Check /proc/version
  local proc_version = read_file_line("/proc/version")
  if proc_version then
    local lower = proc_version:lower()
    if lower:match("microsoft") or lower:match("wsl") then
      -- WSL2 uses a real Linux kernel, WSL1 uses Microsoft kernel
      if lower:match("wsl2") or file_exists("/run/WSL") then
        return true, 2
      end
      return true, 1
    end
  end

  -- Method 2: Check WSL env vars
  if os.getenv("WSL_DISTRO_NAME") or os.getenv("WSLENV") then
    return true, 2
  end

  return false, nil
end

--- Detect SSH / remote session.
--- @return boolean is_ssh
--- @return boolean is_mosh
local function detect_remote()
  local is_ssh = os.getenv("SSH_CONNECTION") ~= nil
    or os.getenv("SSH_CLIENT") ~= nil
    or os.getenv("SSH_TTY") ~= nil

  local is_mosh = false
  -- Mosh sets MOSH_CONNECTION or wraps SSH
  if os.getenv("MOSH_CONNECTION") then
    is_mosh = true
  end

  return is_ssh, is_mosh
end

--- Detect container environments.
--- @return boolean is_docker
--- @return boolean is_podman
--- @return boolean is_kubernetes
local function detect_containers()
  local is_docker = false
  local is_podman = false
  local is_kubernetes = false

  -- Docker detection
  if file_exists("/.dockerenv") then
    is_docker = true
  end

  -- Check cgroup for docker/podman
  local cgroup = read_file_line("/proc/1/cgroup")
  if cgroup then
    if cgroup:match("docker") then
      is_docker = true
    end
    if cgroup:match("podman") or cgroup:match("libpod") then
      is_podman = true
    end
  end

  -- Container environment variable
  local container_env = os.getenv("container")
  if container_env == "podman" then
    is_podman = true
  elseif container_env == "docker" then
    is_docker = true
  end

  -- Kubernetes detection
  if os.getenv("KUBERNETES_SERVICE_HOST") or os.getenv("KUBERNETES_PORT") then
    is_kubernetes = true
  end
  if file_exists("/var/run/secrets/kubernetes.io") then
    is_kubernetes = true
  end

  return is_docker, is_podman, is_kubernetes
end

--- Detect virtualization platforms.
--- @return boolean is_proxmox
--- @return boolean is_opnsense
--- @return boolean is_vps
local function detect_virtualization()
  local is_proxmox = false
  local is_opnsense = false
  local is_vps = false

  -- Proxmox detection
  if file_exists("/etc/pve") or file_exists("/usr/bin/pveversion") then
    is_proxmox = true
  end
  local pve_ver = exec("pveversion")
  if pve_ver then
    is_proxmox = true
  end

  -- OPNsense detection
  if file_exists("/usr/local/etc/inc/opnsense") or file_exists("/conf/config.xml") then
    is_opnsense = true
  end
  if exec("opnsense-version") then
    is_opnsense = true
  end

  -- VPS / Cloud detection heuristics
  local virt = exec("systemd-detect-virt")
  if virt and virt ~= "none" and virt ~= "" then
    is_vps = true
  end

  -- Check DMI for cloud providers
  local dmi = read_file_line("/sys/class/dmi/id/sys_vendor")
  if dmi then
    local lower = dmi:lower()
    if
      lower:match("amazon")
      or lower:match("google")
      or lower:match("microsoft")
      or lower:match("digitalocean")
      or lower:match("hetzner")
      or lower:match("ovh")
      or lower:match("vultr")
      or lower:match("linode")
      or lower:match("scaleway")
    then
      is_vps = true
    end
  end

  return is_proxmox, is_opnsense, is_vps
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Collect all platform information.
--- Results are cached after first call.
--- @param force_refresh? boolean Force re-detection (bypass cache)
--- @return PlatformInfo info Complete platform information
function Platform.detect(force_refresh)
  if _cached_info and not force_refresh then
    return _cached_info
  end

  local os_family, os_release = detect_os()
  local arch = detect_arch()
  local is_wsl, wsl_version = detect_wsl()
  local is_ssh, is_mosh = detect_remote()
  local is_docker, is_podman, is_kubernetes = detect_containers()
  local is_proxmox, is_opnsense, is_vps = detect_virtualization()

  --- @type PlatformInfo
  _cached_info = {
    os = os_family,
    os_release = os_release,
    arch = arch,
    is_wsl = is_wsl,
    wsl_version = wsl_version,
    is_ssh = is_ssh,
    is_mosh = is_mosh,
    is_remote = is_ssh or is_mosh,
    is_docker = is_docker,
    is_podman = is_podman,
    is_container = is_docker or is_podman,
    is_kubernetes = is_kubernetes,
    is_proxmox = is_proxmox,
    is_opnsense = is_opnsense,
    is_vps = is_vps,
    hostname = exec("hostname") or os.getenv("HOSTNAME") or os.getenv("COMPUTERNAME") or "unknown",
    home = os.getenv("HOME") or os.getenv("USERPROFILE") or "",
    shell = os.getenv("SHELL") or os.getenv("COMSPEC") or "",
  }

  return _cached_info
end

--- Check if running on a specific OS.
--- @param target string The OS to check: "linux"|"macos"|"windows"|"bsd"
--- @return boolean matches True if running on the target OS
function Platform.is(target)
  Guard.is_non_empty_string(target, "target")
  local info = Platform.detect()
  return info.os == target:lower()
end

--- Get a human-readable platform summary.
--- @return string summary A formatted summary string
function Platform.summary()
  local info = Platform.detect()
  local parts = {
    string.format("OS: %s (%s)", info.os_release, info.arch),
  }

  if info.is_wsl then
    parts[#parts + 1] = string.format("WSL%d", info.wsl_version or 0)
  end
  if info.is_remote then
    parts[#parts + 1] = info.is_mosh and "Mosh" or "SSH"
  end
  if info.is_docker then
    parts[#parts + 1] = "Docker"
  end
  if info.is_podman then
    parts[#parts + 1] = "Podman"
  end
  if info.is_kubernetes then
    parts[#parts + 1] = "Kubernetes"
  end
  if info.is_proxmox then
    parts[#parts + 1] = "Proxmox"
  end
  if info.is_opnsense then
    parts[#parts + 1] = "OPNsense"
  end
  if info.is_vps then
    parts[#parts + 1] = "VPS/Cloud"
  end

  return table.concat(parts, " | ")
end

--- Reset cached information (useful for testing).
function Platform.reset()
  _cached_info = nil
end

return Platform
