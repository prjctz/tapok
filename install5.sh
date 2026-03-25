#!/bin/bash

#set -u
#set -o pipefail

show_help() {
  cat <<'EOF'
Использование:
  ./script.sh [ПАРАМЕТРЫ]

Параметры:
  --port1=PORT        Порт для telemt. По умолчанию: 8443
  --port2=PORT        Порт для mtprotoproxy. По умолчанию: 993
  --ip=IP             Внешний IP сервера. По умолчанию определяется автоматически
  --domain=DOMAIN     Домен для Fake-TLS. По умолчанию: github.com
  --help              Показать эту справку

Примеры:
  ./script.sh
  ./script.sh --port1=8443 --port2=993
  ./script.sh --port1=8443 --port2=993 --domain=google.com
  ./script.sh --port1=8443 --port2=993 --domain=google.com --ip=203.0.113.10

Примечания:
  - Порты 443, 80, 9091, 8445, 56342 заняты
  - Параметры можно передавать в любом порядке
  - Формат параметров: только --имя=значение
  - Если параметр передан несколько раз, будет использовано последнее значение
EOF
}

show_error() {
  echo "Ошибка: $1" >&2
  echo >&2
  show_help >&2
  exit 1
}

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl
fi

FAKE_DOMAIN="github.com"
#SERVER_IP="111.222.333.444"
SERVER_IP=$(curl -fsSL https://api.ipify.org || curl -fsSL https://ifconfig.me || curl -fsSL https://checkip.amazonaws.com)
PORT1=8443
PORT2=993

#разбор аргументов
for arg in "$@"; do
  case "$arg" in
    --help)
      show_help
      exit 0
      ;;
    --port1=*)
      PORT1="${arg#*=}"
      ;;
    --port2=*)
      PORT2="${arg#*=}"
      ;;
    --ip=*)
      SERVER_IP="${arg#*=}"
      ;;
    --domain=*)
      FAKE_DOMAIN="${arg#*=}"
      ;;
    *)
      show_error "Неизвестный параметр: $arg"
      ;;
  esac
done

[[ -n "$PORT1" ]] || show_error "Порт1 не может быть пустым"
[[ -n "$PORT2" ]] || show_error "Порт2 не может быть пустым"
[[ -n "$SERVER_IP" ]] || show_error "IP не может быть пустым"
[[ -n "$FAKE_DOMAIN" ]] || show_error "Домен не может быть пустым"

matrix_echo() {
  local target="$1"
  local delay="${2:-0.001}"
  local cycles="${3:-4}"
  local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*'
  local cursor="█"
  local output=""
  local rand_char
  local i j

  tput civis 2>/dev/null || printf '\033[?25l'
  trap 'tput cnorm 2>/dev/null || printf "\033[?25h"; printf "\033[0m"' RETURN

  printf '\033[1;32m'

  for ((i=0; i<${#target}; i++)); do
    for ((j=0; j<cycles; j++)); do
      rand_char="${chars:RANDOM%${#chars}:1}"
      printf '\r\033[K%s%s%s' "$output" "$rand_char" "$cursor"
      sleep "$delay"
    done

    output+="${target:i:1}"
    printf '\r\033[K%s%s' "$output" "$cursor"
    sleep "$delay"
  done

  printf '\r\033[K%s\033[0m\n' "$output"
}

matrix_echo  "Метро голден майер представляет Тапок возмездия: кулак ярости."
echo -e "\033[1;32m"
cat << "EOF"
████████╗ █████╗ ██████╗  ██████╗ ██╗  ██╗
╚══██╔══╝██╔══██╗██╔══██╗██╔═══██╗██║ ██╔╝
   ██║   ███████║██████╔╝██║   ██║█████╔╝ 
   ██║   ██╔══██║██╔═══╝ ██║   ██║██╔═██╗ 
   ██║   ██║  ██║██║     ╚██████╔╝██║  ██╗
   ╚═╝   ╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝
EOF
echo -e "\033[0m"

matrix_echo  "Протестировано на Debian 12 на чистом серваке"
matrix_echo  "После установки у тебя будут шифрованные прокси для телеги и панель где ты можешь запускать впн, создавать soks5 прокси для телеги."
matrix_echo  "Отключу файрволы, сделаю запрет пинга и установлю докер и контенера с telemt, mtprotoproxy, 3x-ui, RealiTLScanner из официальных репозиториев."
matrix_echo  "Вначале я просканирую подсеть и подберу домен для маскировки твоего сервера, выдам тебе варианты доменов для выбора."
matrix_echo  "Далее я установклю все контенера и выдам в самом конце доступы ко всему."
matrix_echo  "По мере установки, будут мелькать доступы, они будут продублированы в конце установки."
matrix_echo  "Так же будет небольшой мануал по настройке панели."
echo -e "\033[1;31mЧтобы продолжить, нажмите Enter...\033[0m"
read && echo


# --- UFW ---
if command -v ufw >/dev/null 2>&1; then
    echo "Найден UFW — отключаем..."
    ufw --force disable || true
    systemctl stop ufw || true
    systemctl disable ufw || true
fi

# --- firewalld ---
if systemctl list-unit-files | grep -q firewalld; then
    echo "Найден firewalld — отключаем..."
    systemctl stop firewalld || true
    systemctl disable firewalld || true
fi

# --- nftables (основной в Debian 12) ---
if systemctl list-unit-files | grep -q nftables; then
    echo "Найден nftables — очищаем правила и отключаем..."
    nft flush ruleset || true
    systemctl stop nftables || true
    systemctl disable nftables || true
fi

# --- iptables ---
if command -v iptables >/dev/null 2>&1; then
    echo "Сбрасываем iptables правила..."

    iptables -F || true
    iptables -X || true
    iptables -t nat -F || true
    iptables -t nat -X || true
    iptables -t mangle -F || true
    iptables -t mangle -X || true

    iptables -P INPUT ACCEPT || true
    iptables -P FORWARD ACCEPT || true
    iptables -P OUTPUT ACCEPT || true
fi

# --- ip6tables ---
if command -v ip6tables >/dev/null 2>&1; then
    echo "Сбрасываем ip6tables правила..."

    ip6tables -F || true
    ip6tables -X || true
    ip6tables -P INPUT ACCEPT || true
    ip6tables -P FORWARD ACCEPT || true
    ip6tables -P OUTPUT ACCEPT || true
fi

# отключаем ICMP ping
sysctl -w net.ipv4.icmp_echo_ignore_all=1
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
CONF_ICMP="/etc/sysctl.d/99-disable-icmp.conf"

cat > "$CONF_ICMP" <<EOF
# Disable ICMP echo (managed by script)
net.ipv4.icmp_echo_ignore_all = 1
EOF

sysctl --system


echo "Добавляем порты в sshd_config"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Проверка и добавление портов
add_port() {
    PORT=$1
    #if ! grep -q "^Port $PORT" "$SSHD_CONFIG" && ! grep -q "^#Port $PORT" "$SSHD_CONFIG"; then
    if ! grep -q "^Port $PORT" "$SSHD_CONFIG"; then
        echo "Port $PORT" >> "$SSHD_CONFIG"
        echo "Добавлен порт $PORT"
    else
        echo "Порт $PORT уже существует"
    fi
}

add_port 22
add_port 8445
add_port 56342

echo "Перезапуск SSH"

systemctl restart ssh || true
systemctl restart sshd || true

strip_ansi() {
  sed -r 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g'
}

run_and_capture_tty() {
  local __resultvar="$1"
  local title="$2"
  local cmd="$3"

  local tmpfile rc
  tmpfile="$(mktemp)"
  rc=0

  echo
  echo "======================================"
  echo "$title"
  echo "======================================"
  echo

  if command -v script >/dev/null 2>&1; then
    script -q -c "$cmd" /dev/null | tee "$tmpfile"
    rc=${PIPESTATUS[0]}
  else
    bash -lc "$cmd" | tee "$tmpfile"
    rc=${PIPESTATUS[0]}
  fi

  printf -v "$__resultvar" '%s' "$(cat "$tmpfile")"
  rm -f "$tmpfile"
  return "$rc"
}

run_and_capture() {
  local __resultvar="$1"
  local title="$2"
  local cmd="$3"

  local line
  local output=""
  local rc=0
  local sentinel="__CMD_RC__="

  echo
  echo "======================================"
  echo "$title"
  echo "======================================"
  echo

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == ${sentinel}* ]]; then
      rc="${line#${sentinel}}"
      continue
    fi

    printf '%s\n' "$line"
    output+="$line"$'\n'
  done < <(
    {
      bash -lc "$cmd" 2>&1
      printf '%s%s\n' "$sentinel" "$?"
    }
  )

  printf -v "$__resultvar" '%s' "$output"
  return "$rc"
}

extract_from_marker() {
  local text="$1"
  local marker="$2"

  printf '%s' "$text" \
    | strip_ansi \
    | awk -v marker="$marker" '
        index($0, marker) { found=1 }
        found { print }
      '
}

extract_3xui_block() {
  local text="$1"

  printf '%s' "$text" \
    | strip_ansi \
    | awk '
        {
          prev = cur
          cur = $0

          if (!started && index($0, "Panel Installation Complete!")) {
            if (prev ~ /^═+/) print prev
            print $0
            started=1
            next
          }

          if (started) print
        }
      '
}

extract_scan_report() {
  local text="$1"

  printf '%s' "$text" \
    | strip_ansi \
    | awk '
        index($0, "Отчет сканирования:") { found=1 }
        found { print }
      '
}

extract_unique_domains_from_scan() {
  local text="$1"

  printf '%s\n' "$text" \
    | tr -d '\r' \
    | grep -oE 'cert-domain=("[^"]+"|[^[:space:]]+)' \
    | sed -E '
        s/^cert-domain=//
        s/^"//
        s/"$//
        s/^\*\.//
      ' \
    | awk '!seen[$0]++'
}

echo "Запуск установки..."
echo

read -r -p "Использовать интерактивный режим? [y/N]: " INTERACTIVE
INTERACTIVE="${INTERACTIVE:-n}"

if [[ "$INTERACTIVE" =~ ^[Yy]$ ]]; then
  MODE="interactive"
  echo "Выбран интерактивный режим."
else
  MODE="fast"
  echo "Выбран быстрый режим."
fi

OUT1=""
OUT2=""
OUT3=""
OUT4=""

CMD1="bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer2/refs/heads/main/install2.sh) --port=$PORT1 --ip=$SERVER_IP --domain=$FAKE_DOMAIN"
CMD2="bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer3/refs/heads/main/install3.sh) --port=$PORT2 --ip=$SERVER_IP --domain=$FAKE_DOMAIN"
CMD3="bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)"
CMD4="bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer4/refs/heads/main/install4.sh)"

if [[ "$MODE" == "interactive" ]]; then
  #run_and_capture OUT4 "[1/3] Запускаю сканер доменов для маскировки" "$CMD4"
  #RC4=$?
  run_and_capture_tty OUT4 "[1/3] Сканер доменов" "$CMD4"
  RC4=$?

  SCAN_REPORT="$(extract_scan_report "$OUT4")"
  mapfile -t DOMAINS < <(extract_unique_domains_from_scan "$SCAN_REPORT")

  #printf '%s\n' "$SCAN_REPORT"
  echo "Домены:"
  printf '%s\n' "${DOMAINS[@]}"

  read -r -p "Введите домен для маскировки [$FAKE_DOMAIN]: " FAKE_DOMAIN_INPUT
  FAKE_DOMAIN=${FAKE_DOMAIN_INPUT:-$FAKE_DOMAIN}
  #read -r -p "Введите домен для маскировки: " FAKE_DOMAIN
  #FAKE_DOMAIN="$(printf '%s' "$FAKE_DOMAIN" | sed 's/^\*\.//')"

  if [[ -z "$FAKE_DOMAIN" ]]; then
    echo "Домен не может быть пустым, перезапути установщик"
    exit 1
  fi

  CMD1="bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer2/refs/heads/main/install2.sh) --port=$PORT1 --ip=$SERVER_IP --domain=$FAKE_DOMAIN"
  CMD2="bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer3/refs/heads/main/install3.sh) --port=$PORT2 --ip=$SERVER_IP --domain=$FAKE_DOMAIN"

  run_and_capture OUT1 "[2/3] Установка прокси 8443" "$CMD1"
  RC1=$?

  run_and_capture OUT2 "[3/3] Установка прокси 993" "$CMD2"
  RC2=$?

  run_and_capture_tty OUT3 "[4/3] Установка 3x-ui" "$CMD3"
  RC3=$?
else
  #run_and_capture OUT4 "[1/3] Запускаю сканер доменов для маскировки" "printf '\n' | $CMD4"
  #RC4=$?
  run_and_capture_tty OUT4 "[1/3] Сканер доменов" "printf '\n' | $CMD4"
  RC4=$?

  SCAN_REPORT="$(extract_scan_report "$OUT4")"
  mapfile -t DOMAINS < <(extract_unique_domains_from_scan "$SCAN_REPORT")

  run_and_capture OUT1 "[2/3] Установка прокси 8443" "printf '\n' | $CMD1"
  RC1=$?

  run_and_capture OUT2 "[3/3] Установка прокси 993" "printf '\n' | $CMD2"
  RC2=$?

  run_and_capture OUT3 "[4/3] Установка 3x-ui" "printf '\n\n\n' | $CMD3"
  RC3=$?
fi

# ставлю файрвол
apt install -y ufw

ufw allow 22
ufw allow 8445
ufw allow 56342
ufw allow 80
ufw allow 443
ufw allow $PORT1
ufw allow $PORT2
#ufw allow OpenSSH

# Включаем firewall
ufw --force enable

echo "Статус UFW"
ufw status verbose
ufw status numbered

echo ""
echo -e "\033[0;33m==============================\033[0m"
echo "Команды для firewall:"
echo ""
echo "ufw status numbered"
echo "ufw status verbose"
echo "ufw enable"
echo ""
echo "Отключение:"
echo "ufw disable"
echo "systemctl stop ufw"
echo "systemctl disable ufw"
echo ""
echo "Добавить порт:"
echo "ufw allow <порт>"
echo ""
echo "Удалить порт:"
echo "ufw delete allow <порт>"

echo -e "\033[0;33m==============================\033[0m"


echo
echo -e "\033[1;31m======================================\033[0m"
echo -e "\033[1;31m               ИТОГ\033[0m"
echo -e "\033[1;31m======================================\033[0m"
echo

echo "[1] Подходящие домены:"
printf '%s\n' "${DOMAINS[@]}"

echo "[2] installer2"
RES1="$(extract_from_marker "$OUT1" "Установка завершена!")"
if [[ -n "$RES1" ]]; then
  printf '%s\n' "$RES1"
else
  echo "installer2 модуль не установился"
fi
echo

echo "[3] installer3"
RES2="$(extract_from_marker "$OUT2" "===== TG LINKS =====")"
if [[ -n "$RES2" ]]; then
  printf '%s\n' "$RES2"
else
  echo "installer3 модуль не установился"
fi
echo

echo "[4] 3x-ui"
RES3="$(extract_3xui_block "$OUT3")"
if [[ -n "$RES3" ]]; then
  printf '%s\n' "$RES3"

  #извлекаю порт для файрвола
  XUI_PORT="$(printf '%s\n' "$RES3" \
    | grep -i '^Port:' \
    | awk '{print $2}' \
    | tr -d '\r')"

  if [[ "$XUI_PORT" =~ ^[0-9]+$ ]]; then
    echo "Найден порт 3x-ui: $XUI_PORT"

    #добавляю в ufw
    if command -v ufw >/dev/null 2>&1; then
      echo "Добавляю порт $XUI_PORT в UFW..."
      ufw allow "$XUI_PORT"
    else
      echo "UFW не установлен, пропускаю"
    fi
  else
    echo "Не удалось корректно извлечь порт из 3x-ui"
  fi
else
  echo "3x-ui не установился"
fi
echo

echo "Коды завершения:"
echo "installer4: $RC4"
echo "installer2: $RC1"
echo "installer3: $RC2"
echo "3x-ui:      $RC3"


cat <<'EOF'
В панеле выбрать Подключения - Создать подключение
Протокол - Vless
Порт - 443
Транспорт - TCP (RAW)
Безопасность - Reality
uTLS - Chrome
Target - github.com:443
SNI - github.com
Публичный ключ
Приватный ключ
Нажать под ними кнопку Get New Cert
Выше открыть вкладку Клиент
Flow - xtls-rprx-vision
Внизу нажать Создать

Появится новое подключение, слева от него будет значек кружок Информация, если нажать на него, откроется окно с сылкой подключения, или можно выбрать qr код.

Жмем опять Создать подключение
Протокол - mixed
Порт - 8444
Жмем Создать

В Списке жмем три точки - Информация
Копируем из открывшегося окна информацию (Адрес, 8444, Имя пользователя, Пароль)
Формируем ссылку на подобии как ниже

tg://socks?server=111.111.111.111&port=8444&user=ИмяПользователя&pass=Пароль

Если ты делаешь настройку с доменом, то ставь дополнительные заголовки маскировки
VLESS REALITY XHTTP
User-Agent → Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/538.36
Accept → application/vnd.github+json
Authorization → Bearer ghp_3fD6dE2c7B1KxT7QWZ0YVnX1rPLr
Host → api.github.com

Не забудь добавить новый порт в файрвол:
ufw allow
EOF
