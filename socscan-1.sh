#!/bin/bash
# ==============================================================================
# WordPress Malware Hunter (Popup & ClearFake Edition)
# ==============================================================================
# สคริปต์นี้จะค้นหาและแสดง "เฉพาะชื่อไฟล์" ที่น่าสงสัย โดยไม่แสดงโค้ดที่รกหน้าจอ
# ==============================================================================

# กำหนดโฟลเดอร์เป้าหมาย (หากไม่ได้ระบุ จะใช้ /var/www/html เป็นค่าเริ่มต้น)
TARGET_DIR=${1:-"/var/www/html"}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  WordPress Malware Hunter (Popup/ClearFake) ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Target Directory: ${CYAN}$TARGET_DIR${NC}\n"

# 1. หาไฟล์ .php ที่แอบซ่อนในโฟลเดอร์อัปโหลดรูปภาพ (จุดที่แฮ็กเกอร์ชอบฝัง Backdoor)
echo -e "${YELLOW}[*] 1. สแกนหาไฟล์ Backdoor (ไฟล์ PHP ในโฟลเดอร์ uploads)...${NC}"
find "$TARGET_DIR/wp-content/uploads" -name "*.php" -type f 2>/dev/null | while read -r file; do
    echo -e "  ${RED}[DANGER]${NC} พบไฟล์ PHP ผิดปกติใน uploads: $file"
done
echo "เสร็จสิ้น"
echo ""

# 2. หาไฟล์ที่เพิ่งถูกแก้ไขภายใน 7 วันที่ผ่านมา
echo -e "${YELLOW}[*] 2. สแกนหาไฟล์ที่เพิ่งถูกแก้ไขใน 7 วันล่าสุด...${NC}"
find "$TARGET_DIR" -type f \( -name "*.php" -o -name "*.js" \) -mtime -7 2>/dev/null | while read -r file; do
    echo -e "  ${YELLOW}[RECENT]${NC} ไฟล์เพิ่งถูกแก้: $file"
done
echo "เสร็จสิ้น"
echo ""

# 3. หาไฟล์ที่มีการใช้คำสั่งเข้ารหัสที่มัลแวร์ชอบใช้ (eval, base64_decode, String.fromCharCode)
echo -e "${YELLOW}[*] 3. สแกนหาโค้ดอันตราย (Signatures)...${NC}"
# ใช้ -l เพื่อพ่นแค่ชื่อไฟล์ และ --include เพื่อหาเฉพาะไฟล์เว็บ
grep -rlEi "eval *\(|base64_decode *\(|String\.fromCharCode|atob *\(|document\.write *\(.*unescape" "$TARGET_DIR" --include=\*.{php,js,html} 2>/dev/null | while read -r file; do
    echo -e "  ${RED}[SUSPICIOUS]${NC} พบโค้ดต้องสงสัยใน: $file"
done
echo "เสร็จสิ้น"
echo ""

# 4. หาไฟล์ที่มีบรรทัดยาวผิดปกติ (แฮ็กเกอร์มักจะบีบอัดโค้ดป๊อปอัพให้เหลือบรรทัดเดียวแต่ยาวมากๆ)
echo -e "${YELLOW}[*] 4. สแกนหาไฟล์ที่มีโค้ดบรรทัดยาวผิดปกติ (เกิน 3000 ตัวอักษร)...${NC}"
find "$TARGET_DIR" -type f \( -name "*.php" -o -name "*.js" \) 2>/dev/null -exec awk 'length($0) > 3000 {print FILENAME; exit}' {} \; | while read -r file; do
    echo -e "  ${RED}[OBFUSCATED]${NC} บรรทัดยาวผิดปกติ: $file"
done
echo "เสร็จสิ้น"
echo ""

echo -e "${GREEN}====================================================${NC}"
echo -e "การสแกนเสร็จสมบูรณ์ โปรดตรวจสอบรายชื่อไฟล์ที่แสดงด้านบน"
echo -e "คำแนะนำ: ให้เปิดไฟล์ที่สคริปต์นี้แจ้งเตือนขึ้นมาดูด้วยตาเปล่าอีกครั้ง"
echo -e "${GREEN}====================================================${NC}"
