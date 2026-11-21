# PM Cheat Sheet — Docker (1 หน้า)

> สำหรับผู้จัดการโครงการ/ผู้ดูแลระบบที่ไม่ใช่สาย IT · พิมพ์จาก Markdown เป็น PDF ได้ทันที
> ใช้เมื่อ: ต้องดูสถานะ · ต้องแจ้งปัญหาให้ทีม · ต้อง restart 1 บริการ

## A. เปิดดูสถานะได้เอง — อ่านอย่างเดียว ไม่มีความเสี่ยง

```bash
docker ps --format '{{.Names}}@@{{.Status}}@@{{.Ports}}'   # อะไรกำลังรันอยู่
docker compose ls -a                                       # มี stack อะไร ใช้ไฟล์ compose ที่ไหน
docker logs --tail 80 <container>                          # ทำไมมันบ่น
docker system df                                           # Docker กินพื้นที่เท่าไหร่ (พื้นที่ว่างดิสก์ = df -h)
```

อ่านผลยังไง:

| เห็นอะไร | แปลว่า |
|---|---|
| `Up 3 days` | ปกติ |
| `Restarting` | กำลัง crash loop — ต้องดู log |
| `Exited (1)` | ตายแล้ว ดู ExitCode + log |
| `Exited (0)` | จบงานปกติ (job-type) ไม่ใช่ปัญหา |
| `0.0.0.0:8080->80/tcp` | port 8080 เปิดให้ทั้ง LAN |
| `127.0.0.1:8080->80/tcp` | เปิดเฉพาะเครื่องนั้น (ปลอดภัยกว่า) |
| `[::]:8080->80/tcp` | เปิด IPv6 ด้วย = เทียบเท่า 0.0.0.0 |

## B. ก่อนโทรหาทีม IT — เก็บ 4 อย่างนี้

1. `docker ps -a` ทั้งผลลัพธ์ (ไม่ต้องตัด)
2. `docker logs --tail 80 <container>` — 80 บรรทัดท้าย (ตอบได้เกือบทุกเคส)
3. `docker system df` — ถ้าอาการคือ "ช้า / บันทึกไม่ได้"
4. เวลาเกิดเหตุ + ทำอะไรอยู่ตอนนั้น

ส่งเป็นไฟล์หรือ paste ข้อความธรรมดา ไม่ต้องตีความ — ทีมอ่านเองได้

## C. ทำได้เอง — restart 1 บริการ

```bash
cd <โฟลเดอร์ที่มี docker-compose.yml>
docker compose stop <service>
docker compose up -d <service>
docker logs --tail 50 <container>
```

- ระบุชื่อ service **ทีละตัว** ห้ามใส่หลายตัวพร้อมกัน
- **ห้าม `docker compose down`** — นั่นหยุดทุก service ใน stack
- ถ้าหลัง restart แล้ว log ยัง error เหมือนเดิม → หยุด แล้วส่งต่อ (ข้อ F)

## D. ห้ามทำเอง — ต้องอนุมัติ + backup ก่อน

`docker compose down` · `docker compose down -v` · `docker rm` · `docker rmi` ·
`docker volume rm` · `docker system prune` · `docker exec … rm/mv/chmod`

เหตุผลสั้น ๆ: `down -v` และ `volume rm` = **ข้อมูลหายถาวร**; `prune` = ลบของที่ stack อื่นยังใช้อยู่

## E. เทมเพลตรายงานผล (ก็อปไปวางได้)

```
งาน: …                      เวลา: …
ก่อนแก้ : สถานะ + เวอร์ชัน + health
คำสั่ง  : <คำสั่งจริงที่รัน>
ผล     : สำเร็จ/ไม่สำเร็จ + log บรรทัดจริง
หลังแก้ : สถานะ + เวอร์ชัน + health
กระทบ service อื่น : ไม่มี (เช็คอะไร: …) / ระบุ
rollback: คำสั่งหรือไฟล์ backup ที่ใช้ถอย
```

## F. โทรหาใคร เมื่อไหร่

| สถานการณ์ | ใคร |
|---|---|
| ดูสถานะ / restart 1 service / backup | ทำเองได้ (A, B, C) |
| ทุกอย่างในข้อ D · แก้ DB ตรง ๆ · production เวลาทำการ | เจ้าของระบบ |
| firewall · certificate · โครงสร้าง network · เปลี่ยน image หลัก · อาการซ้ำหลัง rollback | ทีม IT / ผู้ดูแลโฮสต์ |
