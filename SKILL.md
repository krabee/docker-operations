---
name: docker-operations
description: Use when operating a Docker host: safe ops, backups.
version: 1.0.0
author: krabee
license: MIT
metadata:
  hermes:
    tags: [docker, docker-compose, operations, safety, backup, troubleshooting, hub]
    related_skills: [infrastructure-topology-mapping, data-exposure-audit, ssh-access-management, tls-certificate-lifecycle]
created_by: human
language: th
---

# Docker Operations — คู่มือกลางสำหรับงาน Docker ทุก stack

Hub skill สำหรับ **ทุกงาน Docker/Compose บนโฮสต์ใดก็ได้**
ไม่มีชื่อ container / IP / พาธของแอปจริงอยู่ในไฟล์นี้ — ข้อมูลเฉพาะแอปอยู่ใน spoke skill ของคุณเอง
(รูปแบบ: `<app>-operations` หนึ่งไฟล์ต่อหนึ่งระบบ)

**กลุ่มเป้าหมายหลัก:** project manager / ผู้ดูแลระบบที่ไม่ได้เชี่ยวชาญ IT
อ่านจบแล้วต้อง **ทำงานพื้นฐานได้เองอย่างปลอดภัย** และ **รู้ว่าเมื่อไหร่ต้องหยุด**

## 1. When to Use / When NOT

ใช้เมื่อ:
- ต้องดูว่า stack ไหนรันอยู่ / ล่ม / restart loop
- ต้อง restart หรืออัปเดต 1 service โดยไม่กระทบตัวอื่น
- ต้อง backup ก่อนแก้ แล้วรายงานผลต่างก่อน/หลัง
- ต้องตอบคำถามลูกค้า/ทีมว่า "ระบบล่มเพราะอะไร"
- ต้องเตรียม host ใหม่ให้ทีม IT มาต่อ

ไม่ใช้เมื่อ:
- งานเฉพาะแอป (CMS, ฐานข้อมูล, monitoring, smart-home ฯลฯ) → ไป spoke skill ของแอปนั้นก่อน
- งาน firewall/iptables เชิงลึก → `data-exposure-audit`
- งาน cert/TLS → `tls-certificate-lifecycle`

## 2. กติกาทอง 7 ข้อ (อ่านก่อนทุกครั้ง)

1. **อ่านก่อนเขียน** — คำสั่งอ่าน (`docker ps`, `logs`, `inspect`) รันได้เลย ไม่ต้องขออนุญาต
2. **ไม่มี baseline = ห้ามลงมือ** — เก็บ state ก่อนแก้เสมอ (ข้อ 6)
3. **ห้าม `docker compose down`** ใน stack ที่มีข้อมูลจริง — ใช้ `stop <service>` หรือ `up -d <service>` แทน
4. **ห้ามลบ volume / image / container ที่ไม่แน่ใจ** — `rm`, `rmi`, `prune`, `down -v` = ต้องขออนุมัติ + backup ก่อน
5. **secret อยู่ใน `.env` เท่านั้น** — ห้าม hardcode ใน compose, ห้าม commit, ห้ามพิมพ์ลงแชท
6. **ทุกครั้งที่แก้ ต้องรายงาน 5 อย่าง**: อะไรเปลี่ยน / คำสั่งที่รัน / ผลก่อน / ผลหลัง / วิธี rollback
7. **ไม่แน่ใจ = หยุดแล้วถาม** การหยุดถือว่าถูกต้องเสมอ; การเดาแล้วรันถือว่าผิด

## 3. คำศัพท์ 60 วินาที

| คำ | หมายถึง | ภาพที่ควรนึก |
|---|---|---|
| **Image** | แม่พิมพ์สำเร็จรูป (อ่านอย่างเดียว) | แผ่น DVD ติดตั้ง |
| **Container** | เครื่องที่กำลังรันจากแม่พิมพ์นั้น | เครื่องหนึ่งเครื่อง |
| **Volume** | ที่เก็บข้อมูลถาวรที่อยู่นอก container | external HDD |
| **Compose project** | กลุ่ม container ที่ขึ้นพร้อมกันตามไฟล์ `docker-compose.yml` | ทั้งตู้อาคาร |
| **Service** | ชื่อ container หนึ่งตัวใน project นั้น | ห้องหนึ่งห้อง |
| **Host port : Container port** | `8080:80` = เปิดประตูบ้านเลข 8080 เข้าห้อง 80 | เบอร์บ้าน vs เบอร์ห้อง |
| **`.env`** | ไฟล์รหัสผ่าน/ค่าตั้ง ที่ไม่ถูก commit | สมุดรหัสในลิ้นชัก |

> จำง่าย ๆ: **ลบ container = ไม่เสียข้อมูล** (ถ้าข้อมูลอยู่ใน volume) แต่ **ลบ volume = ข้อมูลหายจริง**

## 4. ระดับความเสี่ยงของคำสั่ง

### 🟢 เขียว — อ่านอย่างเดียว รันได้เลย ไม่ต้องถาม
```
docker ps                                    # container ที่รันอยู่
docker ps -a                                 # รวมที่หยุดไปแล้ว
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
docker compose ls -a                         # ทุก project + ไฟล์ compose ที่ใช้
docker inspect <ctr>                         # ค่าระเอียด (ports, mounts, env)
docker logs --tail 100 <ctr>
docker logs --since 24h <ctr> 2>&1 | grep -iE 'error|fatal|panic'
docker stats --no-stream
docker df   →  docker system df
docker image ls --digests
docker volume ls
docker network ls
```

### 🟡 เหลือง — เปลี่ยนสถานะ ทำได้ แต่ต้องรายงานก่อน/หลัง
```
docker compose up -d <service>        # สร้าง/อัปเดตเฉพาะ service นั้น
docker compose restart <service>      # ไม่ลบ container, ข้อมูลอยู่
docker compose stop|start <service>   # หยุด/เริ่ม ไม่ลบ
docker compose pull <service>          # ดึง image ใหม่ (ยังไม่เปลี่ยนของที่รัน)
docker logs -f <ctr>                   # ต้องออกด้วย Ctrl-C
```
กติกาเหลือง: **1 service ต่อ 1 ครั้ง** + `--dry-run`/`config` ก่อนถ้ามี + read-back หลังทำเสมอ

### 🔴 แดง — ห้ามทำเอง ต้องอนุมัติ + backup ก่อน
```
docker compose down            ← หยุดทั้ง project (ทุก service ในนั้นดับหมด)
docker compose down -v         ← ลบ volume = ข้อมูลหายถาวร
docker rm / rm -f <ctr>
docker rmi <image>
docker volume rm <vol>
docker system prune [-a] [--volumes]
docker exec ... rm / mv / dd / chmod -R
การแก้ไฟล์ใน container ด้วย docker exec      ← หายเมื่อ recreate
การแก้ chain DOCKER / DOCKER-ISOLATION ของ iptables
```
ก่อนแดงทุกครั้ง: เก็บ baseline → backup → เขียนคำสั่งที่จะรันให้ผู้ใช้เห็น → รอ "ok"

## 5. Workflow มาตรฐาน 5 ขั้น (ทุกงานที่เปลี่ยนสถานะ)

1. **BASELINE** — `docker ps -a`, `docker inspect` ของ service ที่จะแตะ, `docker system df`, เวอร์ชัน image, และสุขภาพปัจจุบัน (`curl` health endpoint ถ้ามี) → เก็บเป็นไฟล์ `./artifacts/<task>/baseline-<YYYYMMDD>.json`
2. **PLAN + DIFF** — ร่างคำสั่ง/ไฟล์ที่แก้มาให้ดูก่อน + ระบุผลกระทบราย service (ใครจะรีสตาร์ท ใครไม่แตะ) + `docker compose config --quiet` ต้องผ่าน
3. **APPROVE** — ผู้ใช้/เจ้าของระบบ ok (งาน production ต้องได้ ok ชัดเจน)
4. **APPLY** — ทำ **ทีละ service** ไม่ทำทั้ง stack พร้อมกัน
5. **READ-BACK + POST-DIFF** — `docker ps`, `logs --tail 50`, health endpoint, แล้วเทียบกับ baseline เป็นรายตัว ว่า "หาย / ใหม่ / เปลี่ยน" พร้อมหลักฐาน

## 6. เมนูคำสั่งที่ใช้บ่อย (copy-paste ได้)

```bash
# ภาพรวมทั้งเครื่องใน 1 บรรทัด
docker ps --format '{{.Names}}@@{{.Image}}@@{{.Status}}@@{{.Ports}}'

# ใครเปิดประตูออกนอก (0.0.0.0 = เปิดให้ทั้ง LAN/เน็ต)
docker ps --format '{{.Names}}\t{{.Ports}}' | grep -v '127.0.0.1'

# image ที่รันจริง Pin digest หรือยัง
docker ps --format '{{.Image}}' | grep -v '@sha256'     # มีผล = ยังไม่ pin

# project ไหนใช้ไฟล์ compose ที่ไหน
docker compose ls -a

# restart loop / ตายทันที
docker ps -a --filter status=restarting
docker logs --tail 80 <ctr>

# พื้นที่ดิสก์ที่ Docker กิน (อ่านเฉย ๆ ปลอดภัย)
docker system df -v

# ไฟล์ที่ container แก้แล้วกลายเป็น root
docker exec <ctr> ls -ln /path
```

## 7. สูตรงานประจำ 6 อย่าง

| งาน | สูตรย่อ | ต้อง backup |
|---|---|---|
| ดูว่าระบบล่มเพราะอะไร | `ps -a` → `logs --tail 100` → `inspect` | ไม่ |
| restart 1 service | `compose stop <s>` → `compose up -d <s>` → `logs` | ไม่ (แต่เก็บ baseline) |
| อัปเดต image 1 service | baseline → `compose pull <s>` → `up -d <s>` → verify version ใน log | **ใช่** (DB ก่อน) |
| backup ฐานข้อมูล | `docker exec -T <db> <dump cmd> > file.sql.gz` แล้ว `gzip -t` | — |
| backup volume/ไฟล์ | `docker run --rm -v <vol>:/data -v $PWD:/out alpine tar czf /out/<vol>.tgz -C /data .` | — |
| จะลบ image ที่ไม่ใช้ | `docker ps -a --filter ancestor=<image>` **ต้องว่าง** ก่อน `rmi` | ใช่ |

> **สูตร backup ต้องพิสูจน์ว่าใช้ได้** — `gzip -t` ผ่าน + ขนาดไฟล์สมเหตุสมผล + ระบุวันที่ในชื่อไฟล์

## 8. Troubleshooting — 5 อาการยอดฮิต (ไล่ตามลำดับ)

1. **Container ไม่ขึ้น / exit ทันที** → `docker ps -a` (ดู ExitCode) → `docker logs <ctr>` → `docker inspect` (Command, Env, Mounts)
2. **Restart loop** → มัก config ผิด/ไฟล์สิทธิ์ผิด; `docker logs --tail 80`, และ `nginx -t` / `compose config --quiet` ตามชนิด service
3. **เว็บได้ 502 / refused** → เช็ค 3 ชั้น: container รันอยู่ไหม → port mapping ถูกไหม → proxy (Caddy/nginx/cloudflared) ต่อถึง origin ไหม
4. **ดิสก์เต็ม** → `docker system df -v` → หา log/volume โต → **ห้าม prune ก่อนอนุมัติ**
5. **"/wp ไม่มีคำสั่ง" / exec ไม่ได้** → image ไม่มี tool นั้น (official `wordpress` ไม่มี wp-cli), distroless exec ไม่ได้ → ใช้ `docker run --network container:<x>` หรืออ่านจาก volume

## 9. กับดักที่เจอจริง (pitfalls — เก็บจากงานจริง)

**Compose**
1. `docker compose up -d` **recrate ทุก service ที่ image เปลี่ยน** ไม่ใช่แค่ตัวที่ระบุ — ถ้าจะอัปแค่ตัวเดียว ให้ระบุชื่อ service เสมอ
2. `docker compose down` หยุด **ทั้ง project** — ใช้ `stop <service>` แทน
3. Volume ผูกกับ **ชื่อ project** (`-p <name>`); เปลี่ยนชื่อ project = เห็นข้อมูลเป็นชุดใหม่ (เหมือนข้อมูลหาย)
4. แยก project ออกจากกัน = **เรียกกันด้วยชื่อ service ไม่ได้** ต้องใช้ IP/port
5. แก้ไฟล์ใน container ด้วย `docker exec` **หายเมื่อ recreate** — แก้ที่ host/ไฟล์ compose เท่านั้น
6. `docker compose run --rm` **ไม่ใช้ env ของ service** ถ้าไม่ได้ส่ง `env_file`/env ไปเอง

**Docker / host**
7. สมาชิกกลุ่ม `docker` = เทียบเท่า **root** (mount `/` ได้) → การให้สิทธิ์ต้องคิดเหมือนให้ root
8. `docker ps --format` **ไม่มี** `.NetworkSettings` → ต้อง `docker inspect`
9. `docker exec` เขียนไฟล์ออกมาเป็น **root-owned** → ภายหลัง service เขียนทับไม่ได้
10. `docker logs` ของ subprocess อยู่ที่ **stdout** ไม่ใช่ stderr
11. rule firewall ของ Docker อยู่ใน kernel — **หายเมื่อ reboot**; ใส่ได้ที่ `DOCKER-USER` เท่านั้น, Docker ล้าง chain อื่นทิ้งทุกครั้งที่ start, และ `--dport` คือ **port ใน container** ไม่ใช่ host port
12. image ที่ไม่ pin digest = เปลี่ยนเองได้ทุกเมื่อ → pin `@sha256:` เสมอสำหรับ production

**ความปลอดภัย**
13. secret ใน `docker-compose.yml` = ติดไปกับ backup/git → ย้ายเข้า `.env` (chmod 600) และ `.env.example` สำหรับทีม
14. port ที่ขึ้น `0.0.0.0` = เข้าถึงได้จากทั้ง LAN — ควร bind `127.0.0.1` ถ้าไม่ต้องเปิด

## 10. เทมเพลตรายงานผล (ใช้ทุกครั้งที่แก้)

```
งาน: <อะไร>            วันที่/เวลา: <…>
ก่อนแก้ : <สถานะ + เวอร์ชัน + health>
คำสั่ง  : <คำสั่งจริงที่รัน>
ผล     : <สำเร็จ/ไม่สำเร็จ + หลักฐานจาก log บรรทัดจริง>
หลังแก้ : <สถานะ + เวอร์ชัน + health>
กระทบ   : <service อื่นที่ถูกแตะ — ต้องระบุ "ไม่มี" พร้อมหลักฐานว่าเช็คอะไร>
rollback: <คำสั่ง/ไฟล์ backup ที่ใช้ถอยได้>
```

## 11. Escalation — เมื่อไหร่พอ เมื่อไหร่เรียกทีม IT

- **ทำต่อได้เอง:** อ่านสถานะ, restart 1 service ที่มีสูตรในข้อ 7, backup, เก็บ log ส่งต่อ
- **หยุดและถามเจ้าของระบบ:** ทุกอย่างในลิสต์ 🔴, งาน production ช่วงเวลาทำการ, การแตะ DB โดยตรง
- **ส่งต่อทีม IT/ผู้ดูแลโฮสต์:** firewall/iptables, certificate, เปลี่ยนโครงสร้าง network, เปลี่ยน image หลัก, อาการที่เกิดซ้ำหลัง rollback แล้ว

## 12. วิธีต่อยอด (Extension contract)

เมื่อมีแอปใหม่ ให้สร้าง **spoke skill** 1 ตัว ตามรูปแบบนี้ — ห้ามเอา IP/ชื่อ container ของแอปมาใส่ในไฟล์นี้

```
skills/devops/<app>-operations/SKILL.md
  ├─ frontmatter: related_skills: [docker-operations, …]
  ├─ ข้อมูลเฉพาะ: host, IP, ชื่อ service, พาธ compose, port
  ├─ สูตรเฉพาะแอป: backup/restore/upgrade
  └─ references/<topic>.md สำหรับรายละเอียดยาว
```
กติกา: SKILL.md กลาง = วิธีทำ (generic) · spoke = ข้อมูลจริงของไซต์ · memory = pointer เท่านั้น

## 13. References / Scripts (แผน)

- `references/pm-cheatsheet.md` — 1 หน้า A4 สำหรับ PM (คำสั่งเขียว + เทมเพลตรายงาน)
- `references/compose-safety.md` — project/volume/recreate/port mapping + ตัวอย่าง diff
- `references/troubleshooting-decision-tree.md` — อาการ → ขั้นตอนไล่ → หลักฐานที่ต้องเก็บ
- `references/docker-firewall-and-ports.md` — DOCKER-USER, host vs container port, persist หลัง reboot
- `scripts/docker-baseline.sh` — เก็บ baseline (ps -a / inspect / df / image digests) เป็น JSON
- `scripts/docker-backup-volume.sh` — tar volume + `gzip -t` verify + ชื่อไฟล์มีวันที่
- `scripts/compose-plan.sh` — `config --quiet` + แสดงว่าจะ recreate service ใด

## 14. Changelog

- 1.0.0 — ฉบับแรกสำหรับเผยแพร่ (sanitized: ไม่มีชื่อบริษัท/โฮสต์/บัญชีผู้ใช้/IP)
