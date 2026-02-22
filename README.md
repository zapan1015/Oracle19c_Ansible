# Oracle 19c RAC 2-Node 자동화 구축 프로젝트

이 프로젝트는 Ansible과 Vagrant를 사용하여 2개의 노드로 구성된 Oracle 19c Real Application Clusters (RAC) 환경을 자동으로 구축하기 위한 인프라 스트럭처 및 구성 스크립트 모음입니다.

## 📋 프로젝트 개요

Oracle Linux 8 환경에서 Oracle 19c Grid Infrastructure 및 Database를 자동으로 설치하고 구성합니다. VirtualBox와 Vagrant를 통해 로컬 가상화 환경을 준비하며, Ansible을 통해 복잡한 설치 과정을 자동화합니다.

## 🏗️ 시스템 아키텍처

- **가상화**: VirtualBox
- **OS**: Oracle Linux 8 (`island-oraclelinux8` 박스 사용)
- **노드 구성**: 2개 노드 (rac-node1, rac-node2)
- **네트워크**:
  - eth0: NAT (외부 통신)
  - eth1: Public (Host-only, 192.168.56.x)
  - eth2: Private Interconnect (Internal, 192.168.10.x)
- **스토리지**: Shared ASM Disks (10GB x 4EA, 공유형 VDI)

## 🛠️ 사전 요구 사항

1. [VirtualBox](https://www.virtualbox.org/) 설치
2. [Vagrant](https://www.vagrantup.com/) 설치
3. [Ansible](https://www.ansible.com/) (Control Node)
4. Oracle 19c 설치 파일 (준비 필요):
   - LINUX.X64_193000_grid_home.zip
   - LINUX.X64_193000_db_home.zip

## 🚀 시작하기

### 1. 가상 머신 프로비저닝

```bash
vagrant up
```

이 명령어는 2개의 VM을 생성하고 네트워크 및 공유 디스크를 자동으로 설정합니다.

### 2. Ansible 플레이북 실행

```bash
ansible-playbook -i inventory/hosts site.yml
```

전체 설치 프로세스가 순차적으로 진행됩니다.

## 📂 Ansible 역할(Roles) 설명

- **common**: 기본 패키지 설치, 유저/그룹 생성, OS 커널 파라미터 최적화
- **network**: `/etc/hosts` 설정 및 네트워크 인터페이스 구성
- **storage**: ASM 디스크 파티셔닝 및 공유 환경 설정
- **grid**: Oracle Grid Infrastructure 자동 설치 및 ASM 인스턴스 구성
- **database**: Oracle Database 소프트웨어 설치 및 RAC 데이터베이스 생성
- **validation**: 구축 완료 후 RAC 클러스터 상태 및 리소스 확인

## 📝 라이선스

이 프로젝트는 교육 및 테스트 목적으로 작성되었습니다. Oracle 소프트웨어 사용 시 Oracle의 라이선스 정책을 준수해야 합니다.
