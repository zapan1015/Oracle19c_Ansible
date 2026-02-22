# Oracle 19c RAC 2-Node 운영 가이드 (RUNBOOK)

이 문서는 Oracle 19c RAC 2-Node 환경을 처음부터 다시 구축하거나, 이슈 발생 시 복구하기 위한 절차를 기록합니다.

## 📦 사전 준비

### 필수 소프트웨어

| 소프트웨어 | 버전 | 확인 명령 |
|---|---|---|
| VirtualBox | 6.x 이상 | `VBoxManage --version` |
| Vagrant | 2.x 이상 | `vagrant --version` |
| Oracle Linux 8 Box | `island-oraclelinux8` | `vagrant box list` |

### Oracle 설치 미디어 배치

`oracle/` 디렉토리에 아래 파일을 위치시킵니다. (`.gitignore`에 의해 제외됨)

```
c:\Ansible\oracle_19c\oracle\
├── LINUX.X64_193000_grid_home.zip   ← Grid Infrastructure 설치 파일
└── LINUX.X64_193000_db_home.zip     ← Oracle Database 설치 파일
```

> **중요**: `group_vars/all.yml`의 `oracle_grid_image`, `oracle_db_image` 경로와 반드시 일치해야 합니다.

---

## 🚀 전체 구축 절차

### Step 1. VM 초기화 및 기동

```powershell
cd c:\Ansible\oracle_19c
vagrant up
```

- 약 **10~15분** 소요
- rac-node1 (192.168.56.101), rac-node2 (192.168.56.102) 두 VM이 생성됩니다.
- 4개의 공유 ASM 디스크(10GB)가 자동 생성됩니다.

### Step 2. Ansible 플레이북 실행

rac-node1에 SSH 접속 후 자동화 스크립트를 실행합니다.

```powershell
vagrant ssh rac-node1
```

Node1 내부에서 실행:

```bash
cd /vagrant
bash run_ansible.sh
```

> `run_ansible.sh`는 Ansible 자동 설치, Galaxy collection 설치, 플레이북 실행을 모두 자동으로 처리합니다.

**실행 순서**: `common` → `network` → `storage` → `grid` → `database` → `validation`

- 전체 완료까지 약 **60~120분** 소요 (Grid Infrastructure 설치가 가장 오래 걸립니다)

---

## 🔍 각 Role 수동 실행 방법

특정 role만 단독으로 실행하려는 경우 (rac-node1 내부에서):

```bash
cd /vagrant && export ANSIBLE_CONFIG=/vagrant/ansible.cfg

# 특정 role만 실행
ansible-playbook site.yml -i inventory/hosts -e "run_common=false run_storage=false run_network=false run_grid=true run_database=false run_validation=false"

# 특정 태스크부터 재개
ansible-playbook site.yml -i inventory/hosts --start-at-task="Install Grid Infrastructure (Silent)"

# verbose 모드
ansible-playbook site.yml -i inventory/hosts -vvv
```

---

## 🩺 트러블슈팅 기록

### 이슈 1: Grid 설치 시 `ASYNC FAILED on rac-node1`

**원인**: Ansible async 작업이 완료되기 전 poll이 실패하거나, `gridSetup.sh`가 oraInventory를 정상 생성하지 못함  
**해결 방법**:

1. `orainstRoot.sh` 파일이 있는지 확인:

   ```bash
   ls /u01/app/oracle/oraInventory/orainstRoot.sh
   ```

2. 없으면 `gridSetup.sh`를 수동 실행:

   ```bash
   export CV_ASSUME_DISTID=OL7
   sudo -u grid /u01/app/19.0.0/grid/gridSetup.sh \
     -silent -responseFile /u01/app/19.0.0/grid/grid_19c.rsp \
     -ignorePrereq -waitforcompletion
   ```

3. 완료 후 root 스크립트 실행:

   ```bash
   sudo /u01/app/oracle/oraInventory/orainstRoot.sh
   sudo /u01/app/19.0.0/grid/root.sh
   # rac-node2에서도 동일하게 실행
   vagrant ssh rac-node2 -c "sudo /u01/app/19.0.0/grid/root.sh"
   ```

4. Grid 설치 완료 후 Ansible 플레이북 재개:

   ```bash
   ansible-playbook site.yml -i inventory/hosts --start-at-task="Create RECO Disk Group via ASMCA"
   ```

### 이슈 2: `/dev/null` 경로 문제 (Windows PowerShell)

**원인**: Windows PowerShell에서 `2>/dev/null` 구문이 올바르게 처리되지 않음  
**해결**: 명령을 `vagrant ssh` 내부 bash에서 직접 실행하거나 `2>&1`로 대체

---

## 🔄 환경 초기화 및 재시작

### 전체 삭제 (처음부터 재시작)

```powershell
cd c:\Ansible\oracle_19c
vagrant destroy -f
vagrant up
vagrant ssh rac-node1
# 접속 후
cd /vagrant && bash run_ansible.sh
```

### VM만 재시작 (데이터 유지)

```powershell
vagrant reload
```

### VM 일시 중지 / 재개

```powershell
vagrant suspend
vagrant resume
```

---

## 📋 설치 완료 후 검증

```bash
# CRS 전체 리소스 상태 확인
/u01/app/19.0.0/grid/bin/crsctl status res -t

# CRS 서비스 상태 확인
/u01/app/19.0.0/grid/bin/crsctl check crs

# ASM 인스턴스 확인
/u01/app/19.0.0/grid/bin/srvctl status asm

# 데이터베이스 인스턴스 확인
/u01/app/oracle/product/19.0.0/dbhome_1/bin/srvctl status database -d ORCL
```

---

## 🗂️ 주요 파일 구조

```
c:\Ansible\oracle_19c\
├── Vagrantfile              # VM 정의 (2 nodes, ASM disks, 네트워크)
├── site.yml                 # Ansible 메인 플레이북
├── ansible.cfg              # Ansible 설정
├── inventory/hosts          # 인벤토리 (node1: 101, node2: 102)
├── group_vars/all.yml       # 전역 변수 (경로, 사용자, 네트워크 등)
├── run_ansible.sh           # 원클릭 자동화 스크립트
└── roles/
    ├── common/              # OS 기본 설정, 패키지, 사용자
    ├── network/             # /etc/hosts, 네트워크 설정
    ├── storage/             # ASM 디스크 파티셔닝
    ├── grid/                # Grid Infrastructure 설치
    ├── database/            # Oracle DB 설치
    └── validation/          # 구축 완료 검증
```
