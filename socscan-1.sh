#!/bin/bash
# ==============================================================================
# WordPress Malware Hunter v2.0 (Strict Mode)
# ==============================================================================
TARGET_DIR=${1:-"/var/www/html"}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  WP Malware Hunter v2.0 (Strict Obfuscation Scan) ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Target Directory: ${CYAN}$TARGET_DIR${NC}\n"

# 1. หาไฟล์ Backdoor (จุดนี้แม่นยำสูง ไม่ต้องแก้)
echo -e "${YELLOW}[*] 1. สแกนหา Backdoor (PHP ในโฟลเดอร์ uploads)...${NC}"
find "$TARGET_DIR/wp-content/uploads" -name "*.php" -type f 2>/dev/null | while read -r file; do
    echo -e "  ${RED}[DANGER]${NC} พบไฟล์ PHP ซ่อนในรูปภาพ: $file"
done
echo "เสร็จ."

# 2. หาไฟล์ที่เพิ่งถูกแก้ไขใน 7 วัน (ยกเว้นโฟลเดอร์ Cache เพื่อลดการแจ้งเตือนหลอก)
echo -e "\n${YELLOW}[*] 2. สแกนไฟล์ที่ถูกแก้ไขใน 7 วันล่าสุด (ข้าม Cache)...${NC}"
find "$TARGET_DIR" -type f \( -name "*.php" -o -name "*.js" \) -mtime -7 2>/dev/null | grep -viE "/cache/|/updraft/|/backup/" | while read -r file; do
    echo -e "  ${YELLOW}[RECENT]${NC} ไฟล์เพิ่งถูกแก้: $file"
done
echo "เสร็จ."

# 3. สแกนหาโค้ดอันตราย (เพิ่มความรัดกุม)
echo -e "\n${YELLOW}[*] 3. สแกนหาคำสั่งอันตราย (Signatures)...${NC}"
grep -rlEi "eval *\(.*base64|base64_decode *\(|String\.fromCharCode|atob *\(|document\.write *\(.*unescape" "$TARGET_DIR" --include=\*.{php,js} 2>/dev/null | grep -viE "/cache/|/node_modules/|/vendor/" | while read -r file; do
    echo -e "  ${RED}[SUSPICIOUS]${NC} พบโค้ดต้องสงสัยใน: $file"
done
echo "เสร็จ."

# ========================================================
# 4. จุดที่แก้ใหม่: แยกระบบเช็คความยาวบรรทัด PHP กับ JS ให้เด็ดขาด
# ========================================================
echo -e "\n${YELLOW}[*] 4. สแกนหาโค้ดซ่อนเร้นแบบบรรทัดยาวผิดปกติ (>3000 ตัวอักษร)...${NC}"

# 4.1 สำหรับ PHP: ดุเดือดได้เลย เพราะ PHP ปกติไม่มีบรรทัดไหนยาวเกิน 3000 ตัวอักษรอยู่แล้ว
find "$TARGET_DIR" -type f -name "*.php" 2>/dev/null | while read -r file; do
    awk 'length($0) > 3000 {print "  \033[0;31m[OBFUSCATED PHP]\033[0m " FILENAME; exit}' "$file"
done

# 4.2 สำหรับ JS: กรองแบบเข้มงวดสุดๆ ตัด .min.js, -min.js, โฟลเดอร์ cache, และไลบรารีมาตรฐานทิ้งทั้งหมดก่อนสแกน
find "$TARGET_DIR" -type f -name "*.js" 2>/dev/null | \
grep -viE "\.min\.js$|-min\.js$|/cache/|/node_modules/|/vendor/|/jquery.*\.js" | \
while read -r file; do
    awk 'length($0) > 3000 {print "  \033[0;31m[OBFUSCATED JS]\033[0m  " FILENAME; exit}' "$file"
done
echo "เสร็จ."

echo -e "\n${GREEN}====================================================${NC}"
echo -e " สแกนเสร็จสิ้น!"
echo -e "${GREEN}====================================================${NC}"
