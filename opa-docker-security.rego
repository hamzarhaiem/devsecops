package main
import rego.v1

# Do Not store secrets in ENV variables
secrets_env := [
  "passwd",
  "password",
  "pass",
  "secret",
  "key",
  "access",
  "api_key",
  "apikey",
  "token",
  "tkn",
]

# ENV secrets
deny contains msg if {
  some i
  input[i].Cmd == "env"
  val := input[i].Value
  contains(lower(val[_]), secrets_env[_])
  msg := sprintf("Line %d: Potential secret in ENV key found: %s", [i, val])
}

# Do not use 'latest' tag for base images
deny contains msg if {
  some i
  input[i].Cmd == "from"
  parts := split(input[i].Value[0], ":")
  count(parts) > 1
  lower(parts[1]) == "latest"
  msg := sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

# Avoid curl bashing
deny contains msg if {
  some i
  input[i].Cmd == "run"
  val := concat(" ", input[i].Value)
  matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
  count(matches) > 0
  msg := sprintf("Line %d: Avoid curl bashing", [i])
}

# Do not upgrade your system packages
upgrade_commands := [
  "apk upgrade",
  "apt-get upgrade",
  "dist-upgrade",
]

deny contains msg if {
  some i
  input[i].Cmd == "run"
  val := concat(" ", input[i].Value)
  contains(val, upgrade_commands[_])
  msg := sprintf("Line: %d: Do not upgrade your system packages", [i])
}

# Do not use ADD if possible
deny contains msg if {
  some i
  input[i].Cmd == "add"
  msg := sprintf("Line %d: Use COPY instead of ADD", [i])
}

# Any user...
any_user if {
  some i
  input[i].Cmd == "user"
}

# ...but require non-root
deny contains msg if {
  not any_user
  msg := "Do not run as root, use USER instead"
}

forbidden_users := [
  "root",
  "toor",
  "0",
]

deny contains msg if {
  some i
  input[i].Cmd == "user"
  val := input[i].Value
  contains(lower(val[_]), forbidden_users[_])
  msg := sprintf("Line %d: Do not run as root: %s", [i, val])
}

# Do not sudo
deny contains msg if {
  some i
  input[i].Cmd == "run"
  val := concat(" ", input[i].Value)
  contains(lower(val), "sudo")
  msg := sprintf("Line %d: Do not use 'sudo' command", [i])
}
