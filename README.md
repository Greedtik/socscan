# SOC Scanner (Ultimate Go-Bag Edition) 🚀

**SOC Scanner** คือเครื่องมือตรวจสอบความปลอดภัยและวิเคราะห์พฤติกรรมผิดปกติบนระบบ Linux (Incident Response / Triage Tool) แบบ **Agentless** และ **Standalone** ออกแบบมาเพื่อให้นักบริหารจัดการระบบ (System Engineer) และทีมความปลอดภัย (SOC/IR) สามารถตรวจสอบเครื่องที่สงสัยว่าโดนบุกรุกได้ทันทีโดยไม่ต้องติดตั้งโปรแกรมใดๆ ลงในเครื่องเป้าหมาย

## ✨ คุณสมบัติเด่น (Features)

* **Malware & Crypto Miner Detection**: ตรวจจับโปรเซสขุดเหรียญยอดฮิตและไฟล์อันตรายในโฟลเดอร์ชั่วคราว (`/tmp`, `/var/tmp`)
* **Reverse Shell Detection**: ตรวจสอบการเชื่อมต่อ Shell กลับไปยังเครื่องแฮกเกอร์ ทั้งจากโปรเซสใน Memory และ Network Socket
* **Suspicious Port Scanning**: สแกนพอร์ตอันตรายพร้อมระบุประเภทของมัลแวร์หรือเครื่องมือที่มักใช้พอร์ตนั้นๆ (เช่น Metasploit, RATs)
* **Privileged User Audit**: ค้นหาบัญชีแปลกปลอมที่มีสิทธิ์ Root (UID 0) หรือบัญชีที่ไม่ได้ตั้งรหัสผ่าน
* **Persistence Mechanisms**: ตรวจสอบการฝังตัวผ่าน Cron Jobs และการแอบวาง SSH Authorized Keys
* **Container Security (Docker)**: ตรวจสอบความเสี่ยงในเลเยอร์ Container เช่น การรันแบบ Privileged หรือการ Mount Root Filesystem
* **Targeted CVE Online Scan**: ตรวจสอบช่องโหว่ล่าสุดของแพ็กเกจสำคัญ (เช่น `sudo`) โดยเปรียบเทียบข้อมูลแบบ Real-time กับฐานข้อมูล **OSV (Open Source Vulnerabilities) API** ของ Google

## 🚀 วิธีการใช้งาน (Usage)

### 1. รันทันทีผ่านคำสั่งเดียว (One-liner Execute)
หากคุณนำโค้ดขึ้น GitHub Repository แล้ว สามารถสั่งรันสคริปต์ได้โดยไม่ต้องดาวน์โหลดไฟล์ลงดิสก์:

```bash
curl -sL https://raw.githubusercontent.com/Greedtik/socscan/refs/heads/main/socscan.sh | sudo bash
```
*(อย่าลืมเปลี่ยน `USERNAME/REPO` เป็น URL ของ Git ของคุณ)*

### 2. รันแบบ Manual (Manual Execution)
หากคุณดาวน์โหลดไฟล์มาไว้ที่เครื่องเป้าหมายแล้ว:

```bash
chmod +x socscan.sh
sudo ./socscan.sh
```

## 📋 ความต้องการของระบบ (Requirements)

* **Operating System**: รองรับ Linux หลาย Distro (Ubuntu, Debian, CentOS, RHEL, Rocky Linux, AlmaLinux)
* **Privileges**: จำเป็นต้องใช้สิทธิ์ **Root** (`sudo`) ในการรันเพื่อให้สามารถสแกนโปรเซสและ Network Socket ได้ครบถ้วน
* **Dependencies**: 
    * เครื่องมือพื้นฐาน: `curl`, `ss`, `ps`, `grep`, `awk` (ปกติมีติดเครื่องอยู่แล้ว)
    * แนะนำให้ติดตั้ง: `jq` (เพื่อให้โมดูล CVE สามารถดึงรายละเอียดช่องโหว่ออกมาแสดงผลได้สวยงามและอ่านง่ายขึ้น)

## 🖥️ ตัวอย่างการแสดงผล (Output Example)

สคริปต์จะแสดงผลการสแกนแบบ Real-time พร้อมระบบสีเพื่อช่วยให้กวาดสายตาหาความผิดปกติได้รวดเร็ว:
* 🟢 **[OK] / [SAFE]**: ปลอดภัย ไม่พบความผิดปกติ
* 🟡 **[WARNING] / [INFO]**: พบสิ่งที่น่าสงสัย ควรตรวจสอบเพิ่มเติม
* 🔴 **[FOUND ALERT] / [VULNERABLE]**: พบภัยคุกคาม มัลแวร์ หรือช่องโหว่ร้ายแรงที่ต้องแก้ไขทันที

## ⚠️ คำเตือน (Disclaimer)

เครื่องมือนี้จัดทำขึ้นเพื่อใช้ในการตรวจสอบความปลอดภัยและวิเคราะห์ระบบเบื้องต้นเท่านั้น ผู้พัฒนาไม่รับผิดชอบต่อความเสียหายใดๆ ที่อาจเกิดขึ้นจากการนำไปใช้งานในทางที่ผิด หรือผลกระทบจากการตรวจสอบระบบโปรดักชั่นที่มีความอ่อนไหวสูง โปรดทดสอบในสภาพแวดล้อมจำลองก่อนใช้งานจริง
