#!/bin/sh
# Apple MacBook SKU Generator — Enhanced Menu Version
# Melody's SKU Tool with robust CSV parsing, full menu, and battery/charger display

CSV_FILE="Apple SKU Key - Key.csv"

if [ ! -f "$CSV_FILE" ]; then
  echo "❌ CSV file '$CSV_FILE' not found in current directory!"
  exit 1
fi

trim() { printf "%s" "$1" | awk '{$1=$1; print}'; }

ram_code() {
  case "$1" in
    8) echo "3" ;;
    16) echo "4" ;;
    32) echo "6" ;;
    36) echo "A" ;;
    40) echo "D" ;;
    48) echo "B" ;;
    64) echo "7" ;;
    *) echo "?" ;;
  esac
}

ssd_code() {
  case "$1" in
    10) echo "D" ;;
    128) echo "4" ;;
    256) echo "5" ;;
    512) echo "6" ;;
    1024) echo "8" ;;
    2048) echo "A" ;;
    4096) echo "B" ;;
    *) echo "?" ;;
  esac
}

color_code() {
  uc=$(printf "%s" "$1" | tr '[:lower:]' '[:upper:]')
  case "$uc" in
    "GRAY"|"SPACE GRAY") echo "G" ;;
    "SILVER") echo "S" ;;
    "ROSE GOLD") echo "R" ;;
    "GOLD") echo "D" ;;
    "BLUE"|"MIDNIGHT BLUE") echo "M" ;;
    "BLACK"|"SPACE BLACK") echo "B" ;;
    *) echo "?" ;;
  esac
}

cond_code() {
  case "$1" in
    A|a) echo "A" ;;
    B|b) echo "B" ;;
    C|c) echo "C" ;;
    D|d) echo "D" ;;
    *) echo "?" ;;
  esac
}

print_boxed() {
  FULLSKU="$1"; MODEL_ORDER="$2"; MODEL="$3"; MODEL_BASIC="$4"; MODEL_EMC="$5"
  BASESKU="$6"; YEAR="$7"; CPU="$8"; GPU="$9"; BATTERY="${10}"; CHARGER="${11}"
  RAMCODE="${12}"; RAMVAL="${13}"; SSDCODE="${14}"; SSDVAL="${15}"
  CONDCODE="${16}"; CONDVAL="${17}"; COLORCODE="${18}"; COLORVAL="${19}"

  echo "╔$(printf '═%.0s' $(seq 1 70))╗"
  printf "║ %-68s ║\n" "GENERATED SKU REPORT"
  echo "╠$(printf '═%.0s' $(seq 1 70))╣"
  printf "║ %-15s: %-48.48s ║\n" "FULL SKU" "$FULLSKU"
  printf "║ %-15s: %-48.48s ║\n" "MODEL ORDER" "$MODEL_ORDER"
  printf "║ %-15s: %-48.48s ║\n" "MODEL" "$MODEL"
  printf "║ %-15s: %-48.48s ║\n" "MODEL BASIC" "$MODEL_BASIC"
  printf "║ %-15s: %-48.48s ║\n" "MODEL EMC" "$MODEL_EMC"
  printf "║ %-15s: %-48.48s ║\n" "BASE SKU" "$BASESKU"
  printf "║ %-15s: %-48.48s ║\n" "YEAR" "$YEAR"
  printf "║ %-15s: %-48.48s ║\n" "CPU" "$CPU"
  printf "║ %-15s: %-48.48s ║\n" "GPU" "$GPU"
  printf "║ %-15s: %-48.48s ║\n" "Battery Code" "$BATTERY"
  printf "║ %-15s: %-48.48s ║\n" "Charger" "$CHARGER"
  echo "╟$(printf '─%.0s' $(seq 1 70))╢"
  printf "║ %-15s: %-48.48s ║\n" "RAM Code" "${RAMCODE} (${RAMVAL} GB)"
  printf "║ %-15s: %-48.48s ║\n" "SSD Code" "${SSDCODE} (${SSDVAL} GB)"
  printf "║ %-15s: %-48.48s ║\n" "Condition" "${CONDCODE} (${CONDVAL})"
  printf "║ %-15s: %-48.48s ║\n" "Color Code" "${COLORCODE} (${COLORVAL})"
  echo "╚$(printf '═%.0s' $(seq 1 70))╝"
}

view_models() {
  echo ""
  echo "=== AVAILABLE MODELS ==="
  awk -F, 'NR>1 {printf "%-8s — %-18s — %s\n", $9, $1, $6}' "$CSV_FILE" | sort -u
}

view_config_options() {
  echo ""
  echo "=== CONFIGURATION OPTIONS ==="
  echo "RAM:"
  echo "  8 GB  → 3"
  echo "  16 GB → 4"
  echo "  32 GB → 6"
  echo "  36 GB → A"
  echo "  40 GB → D"
  echo "  48 GB → B"
  echo "  64 GB → 7"
  echo ""
  echo "SSD:"
  echo "  128 GB → 4"
  echo "  256 GB → 5"
  echo "  512 GB → 6"
  echo "  1 TB   → 8"
  echo "  2 TB   → A"
  echo "  4 TB   → B"
  echo ""
  echo "Condition:"
  echo "  A → Excellent"
  echo "  B → Good"
  echo "  C → Fair"
  echo "  D → Poor"
  echo ""
  echo "Color Codes:"
  echo "  Gray / Space Gray → G"
  echo "  Silver → S"
  echo "  Rose Gold → R"
  echo "  Gold → D"
  echo "  Blue / Midnight Blue → M"
  echo "  Black / Space Black → B"
}

lookup_by_base() {
  printf "Enter Base SKU: "
  read bsku
  bsku=$(trim "$bsku")
  [ -z "$bsku" ] && { echo "Base SKU required."; return; }
  echo ""
  echo "Matches for Base SKU $bsku:"
  awk -F, -v bsku="$bsku" 'NR>1 && $3==bsku {
    printf "%-18s — %-6s — %-25s — %s — Battery: %s\n", $1, $9, $4, $6, $12
  }' "$CSV_FILE"
}

generate_sku() {
  printf "Enter Model Basic (e.g., A1706): "
  read model_basic
  model_basic=$(trim "$model_basic")
  [ -z "$model_basic" ] && { echo "Model Basic required."; return; }

  printf "Enter CPU (partial ok, leave blank to list all for Model Basic): "
  read cpuq
  cpuq=$(trim "$cpuq")

  tmp=$(mktemp)
  awk -F, -v mb="$model_basic" -v cq="$cpuq" 'BEGIN{IGNORECASE=1} NR>1 {
    if ($9 == mb) {
      low_cpu = tolower($4); low_gpu = tolower($5); low_q = tolower(cq)
      if (low_q == "" || index(low_cpu, low_q) > 0 || index(low_gpu, low_q) > 0)
        print $0
    }
  }' "$CSV_FILE" > "$tmp"

  count=$(wc -l < "$tmp" | tr -d ' ')
  [ "$count" -eq 0 ] && { echo "No matches found."; rm -f "$tmp"; return; }

  if [ "$count" -gt 1 ]; then
    echo ""
    echo "Multiple matches found for $model_basic:"
    i=1
    while IFS= read -r line; do
  cpuv=$(printf "%s" "$line" | awk -F, '{gsub(/^"|"$/,"",$4); print $4}')
  gpuv=$(printf "%s" "$line" | awk -F, '{gsub(/^"|"$/,"",$5); print $5}')
  model=$(printf "%s" "$line" | awk -F, '{gsub(/^"|"$/,"",$1); print $1}')
  yearv=$(printf "%s" "$line" | awk -F, '{gsub(/^"|"$/,"",$6); print $6}')
  printf "  %d) %s — %s — %s (%s)\n" "$i" "$cpuv" "$gpuv" "$model" "$yearv"
      i=$((i+1))
    done < "$tmp"
    printf "Enter the number to use that CPU/GPU, or 0 to cancel: "
    read sel
    [ "$sel" -eq 0 ] && { echo "Cancelled."; rm -f "$tmp"; return; }
    line=$(awk "NR==$sel {print; exit}" "$tmp")
  else
    line=$(cat "$tmp")
  fi
  rm -f "$tmp"

  model=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[0] if len(r)>0 else "")
PY
)
  model_order=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[1] if len(r)>1 else "")
PY
)
  base_sku=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[2] if len(r)>2 else "")
PY
)
  cpu_val=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[3] if len(r)>3 else "")
PY
)
  gpu_val=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[4] if len(r)>4 else "")
PY
)
  year_val=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[5] if len(r)>5 else "")
PY
)
  charger_val=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[7] if len(r)>7 else "")
PY
)
  model_basic_out=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[8] if len(r)>8 else "")
PY
)
  model_emc=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[9] if len(r)>9 else "")
PY
)
  battery_val=$(LINE="$line" python3 - <<'PY'
import os, csv
r = next(csv.reader([os.environ['LINE']]))
print(r[11] if len(r)>11 else "")
PY
)

  printf "Enter RAM (GB): "
  read ram
  printf "Enter SSD (GB): "
  read ssd
  printf "Enter Condition (A/B/C/D): "
  read cond
  printf "Enter Color: "
  read color

  ramcode=$(ram_code "$ram")
  ssdcode=$(ssd_code "$ssd")
  condcode=$(cond_code "$cond")
  colorcode=$(color_code "$color")

  fullsku="${base_sku}${ramcode}${ssdcode}${condcode}-${colorcode}"
  print_boxed "$fullsku" "$model_order" "$model" "$model_basic_out" "$model_emc" "$base_sku" \
    "$year_val" "$cpu_val" "$gpu_val" "$battery_val" "$charger_val" "$ramcode" "$ram" "$ssdcode" "$ssd" \
    "$condcode" "$cond" "$colorcode" "$color"
}



lookup_by_emc() {
  printf "Enter EMC Number: "
  read emc
  emc=$(trim "$emc")
  [ -z "$emc" ] && { echo "EMC required."; return; }
  echo ""
  echo "Matches for EMC $emc:"
  awk -F, -v emc="$emc" 'NR>1 && $10==emc {
    printf "%-18s — %-6s — %-25s — %s — Battery: %s — Base SKU: %s\n", $1, $9, $4, $6, $12, $3
  }' "$CSV_FILE"
}

while true; do
  echo ""
  echo "=== MAIN MENU ==="
  echo "1. Generate SKU Code"
  echo "2. View Available Models"
  echo "3. View Configuration Options"
  echo "4. Lookup by Base SKU"
  echo "5. Lookup by EMC"
  echo "6. Exit"
  printf "Choose: "
  read choice
  case "$choice" in
    1) generate_sku ;;
    2) view_models ;;
    3) view_config_options ;;
    4) lookup_by_base ;;
    5) lookup_by_emc ;;
    6) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
