Thông báo bảo mật · SBU1
Ban hành 30/10/2026
Cập nhật 02/11/2026
Mức ưu tiên: khẩn
Rà soát và vá lỗ hổng Linux kernel
Cuối tháng 10/2026 có hai lỗ hổng kernel Linux cần xử lý ngay. Một lỗ hổng đang bị hacker khai thác thật, lỗ hổng còn lại cho phép chiếm quyền root từ xa. Amazon Linux đã có bản vá cho cả hai, Ubuntu thì chưa có bản vá cho lỗ hổng thứ hai. Mọi dự án có máy Linux (server on-premise, EC2, máy build) cần rà soát theo hướng dẫn dưới đây và báo lại kết quả. Máy làm việc cá nhân của member làm theo mục riêng.

Thay đổi ngày 02/11/2026
Amazon Linux 2 và 2023 (kể cả kernel mặc định 6.1) đã có bản vá CVE-2026-98432 từ 30/10. Bản trước ghi "chưa có" là sai.
Tắt MPTCP chưa đủ. Bổ sung luật chặn gói tin TCP có IP options cho máy Ubuntu (bước 3.2).
Bổ sung hướng dẫn cho EKS, ECS, Fargate, RDS theo bulletin của AWS, và mục máy làm việc cá nhân.
Nhóm tấn công dùng Fragnesia đã chiếm server tại Nhật. Ưu tiên rà server của khách Nhật có chạy PHP.
Không cần nhập file báo cáo nữa. PM trả lời thread Teams theo mẫu ngắn ở bước 5.
Việc cần làm ngay
Chạy script rà soát trên từng máy Linux của dự án. Làm trước với server của khách Nhật, server chạy PHP và máy mở cổng ra Internet.
Máy chưa vá Fragnesia: cập nhật kernel và reboot. Máy chạy web/PHP thì kiểm tra dấu hiệu xâm nhập trước khi reboot.
Amazon Linux: cập nhật kernel và reboot là vá xong cả hai lỗ hổng. Ubuntu: tắt MPTCP và chặn gói tin có IP options trong lúc chờ bản vá CVE-2026-98432.
Trả lời thread Teams của SBU1 theo mẫu ngắn ở bước 5.
Các lỗ hổng cần biết
Lỗ hổng Nguy cơ Tình hình Bản vá
Fragnesia
CVE-2026-46300
User thường lên root, có thể thoát container. CVSS 7.8 Đang bị khai thác
CISA đưa vào danh sách KEV ngày 28/10. Hacker vào máy qua lỗi PHP (PHP2Shell) rồi dùng lỗi này lên root. Khoảng 25 server ở Mỹ, Nhật, Đài Loan, Hàn Quốc đã bị chiếm. Đã có từ 05/2026
Ubuntu, Amazon Linux, RHEL, Debian đều đã vá.
TCP use-after-free
CVE-2026-98432
Tấn công từ xa, không cần đăng nhập, có thể chiếm root. CVSS 9.8 Đã chứng minh chiếm root
Anthropic công bố ngày 27/10 đã chiếm root từ xa trên server có MPTCP, mã khai thác chưa công khai. Lỗi gốc kích hoạt được qua mọi cổng TCP IPv4. Chưa ghi nhận khai thác thật. Ubuntu: chưa có
Amazon Linux: đã có
Amazon Linux 2 và 2023, mọi dòng kernel, vá từ 30/10.
PwnEscape
CVE-2026-99999
Máy ảo đọc được bộ nhớ của máy chủ vật lý. CVSS 9.3 Chưa ghi nhận khai thác
Chỉ liên quan dự án tự vận hành KVM/QEMU/Proxmox. EC2 do AWS tự vá phía host. Vá trên máy host. Vá trong máy ảo không có tác dụng.
Máy nào cần rà soát
Server và máy ảo Linux của dự án, kể cả máy staging, máy build CI, máy chạy batch.
EC2 trên AWS. EC2 không mặc định là Ubuntu. AMI mặc định khi tạo từ console là Amazon Linux 2023, nhiều dự án lại chọn Ubuntu. Hãy xem thực tế bằng cat /etc/os-release hoặc dùng script ở bước 1, script tự nhận diện.
Máy chạy Docker/Kubernetes: container dùng chung kernel với máy host, nên phải vá máy host và node. Cập nhật image không vá được kernel.
Máy làm việc cá nhân của member (Ubuntu, WSL2): làm theo mục riêng.
Dự án có nhiều EC2 có thể chạy script hàng loạt bằng AWS Systems Manager → Run Command (tài liệu AWS-RunShellScript), hoặc xem danh sách máy bị ảnh hưởng trong Amazon Inspector nếu đã bật.
Dịch vụ AWS quản lý (theo bulletin AWS ngày 01/11)
Dịch vụ Dự án cần làm
EKS Cập nhật node group, node tự quản lý hoặc Karpenter lên EKS-optimized AMI v20261031 trở lên. EKS Auto Mode tự thay node, dự kiến xong trước 06/11.
ECS trên EC2 Cập nhật kernel và reboot, hoặc thay instance bằng ECS-optimized AMI 20261031 trở lên.
Fargate Task chạy từ 01/11 đã dùng bản vá. Task chạy từ trước đó vẫn dùng bản cũ: chạy lại (force new deployment) để thay.
RDS / Aurora Bản vá OS có từ 03/11. Áp maintenance khi có. Không mở cổng database ra Internet.
EC2 sau NLB (TCP), Global Accelerator, PrivateLink Các dịch vụ này chuyển nguyên gói tin xuống server, nên server phía sau vẫn bị lộ. Vá như EC2 thường.
EC2 sau ALB, CloudFront, API Gateway AWS đã xử lý ở tầng hạ tầng. Vẫn phải vá server phía sau, AWS khuyến nghị trong 30 ngày.
Lambda Không cần làm gì.
Bước 1
Chạy script rà soát
Dán nguyên khối lệnh dưới đây vào terminal của từng máy. Script chỉ đọc thông tin, không thay đổi gì trên máy. Chạy được trên Ubuntu 20.04 trở lên, Amazon Linux 2 và Amazon Linux 2023.

sudo bash -s <<'EOF'
echo "===== Rà soát kernel: $(hostname) | $(date '+%F %T')"
. /etc/os-release && echo "OS              : $PRETTY_NAME"
echo "Kernel đang chạy: $(uname -r)"
echo "MPTCP           : $(sysctl -n net.mptcp.enabled 2>/dev/null || echo 'kernel không hỗ trợ')"
echo "--- Socket MPTCP đang lắng nghe (chỉ có dòng tiêu đề = không có):"
ss -Mltnp 2>/dev/null || echo "(bản ss cũ, không kiểm tra được)"
echo "--- Module IPsec ESP đang nạp:"
lsmod | grep -E '^(esp4|esp6|espintcp) ' || echo "(không có)"
echo "--- Trạng thái vá theo CVE:"
if command -v pro >/dev/null 2>&1; then
  for c in CVE-2026-46300 CVE-2026-98432; do pro fix --dry-run "$c"; done
elif command -v dnf >/dev/null 2>&1; then
dnf -q --releasever=latest updateinfo list --all --cve CVE-2026-46300 --cve CVE-2026-98432
elif command -v yum >/dev/null 2>&1; then
yum -q updateinfo list all --cve CVE-2026-46300 --cve CVE-2026-98432
else
echo "(không nhận diện được trình quản lý gói)"
fi
echo "--- Cần reboot để kernel mới có hiệu lực?"
if [ -f /var/run/reboot-required ]; then echo "CÓ: đã cài kernel mới nhưng chưa reboot"
elif command -v dnf >/dev/null 2>&1; then dnf -q needs-restarting -r
elif command -v needs-restarting >/dev/null 2>&1; then needs-restarting -r
else echo "không"
fi
echo "===== Hết"
EOF
Copy
Đọc kết quả
Kernel đang chạy
Ghi lại để điền báo cáo. Ubuntu đã vá Fragnesia khi kernel bản thường (generic) từ 5.15.0-181 (22.04), 6.8.0-124 (24.04), 6.17.0-35 (24.04 HWE), 7.0.0-22 (26.04) trở lên. Kernel bản AWS/Azure/GCP có số khác, nên dựa vào dòng pro fix là chính xác nhất. Ubuntu 20.04 dùng kernel 5.4 mặc định thì không bị Fragnesia.
MPTCP
1 là đang bật, cần tắt ở bước 3. 0 là đã tắt.
Socket MPTCP
Có dòng nào dưới tiêu đề nghĩa là có dịch vụ đang nhận kết nối MPTCP. Sau khi tắt MPTCP phải restart các dịch vụ này. Dịch vụ viết bằng Go 1.24 trở lên mặc định mở MPTCP.
Module ESP
Máy không dùng IPsec VPN mà vẫn thấy esp4, esp6, espintcp là dấu hiệu đáng ngờ. Xem bước 2.3.
pro fix (Ubuntu)
“is resolved” hoặc “does not affect” là ổn. “fix is not yet available” với CVE-2026-98432 là đúng tình trạng hiện tại, làm bước 3. Nếu báo có bản vá chưa cài thì làm bước 2.
dnf / yum (Amazon Linux)
Có dòng ALAS cho CVE nghĩa là đã có bản vá (đánh dấu i là đã cài). Từ 30/10 cả hai CVE đều đã có bản vá trên Amazon Linux, nên dòng nào chưa có i thì làm bước 2.1.
Cần reboot
“CÓ” nghĩa là kernel mới đã cài nhưng máy vẫn chạy kernel cũ, tức là chưa được vá. Đây là trường hợp hay gặp nhất trên máy có cập nhật tự động.
Bước 2
Vá Fragnesia (CVE-2026-46300)
Máy chạy web, PHP hoặc mở cổng ra Internet: làm bước 2.3 trước khi reboot.
Kiểu tấn công này chỉ sửa file trong bộ nhớ, không sửa trên đĩa. Reboot xong là mất hết dấu vết.

2.1 · Cập nhật kernel và reboot
Ubuntu
20.04 HWE, 22.04, 24.04, 26.04
sudo apt update
sudo apt full-upgrade -y
sudo reboot

# Sau khi máy lên lại, kiểm tra:

uname -r
sudo pro fix CVE-2026-46300
Copy
Amazon Linux
2023 và 2

# Amazon Linux 2023 (phải có --releasever=latest,

# nếu không dnf chỉ lấy gói cùng đợt với AMI cũ)

sudo dnf update -y kernel --releasever=latest

# Amazon Linux 2

sudo yum update -y kernel
sudo reboot

# Sau khi máy lên lại: vá cả Fragnesia và CVE-2026-98432

uname -r
Copy
Nên chụp snapshot EBS hoặc AMI trước khi nâng kernel cho server production, và báo khách hàng nếu cần xin lịch bảo trì.

2.2 · Nếu chưa reboot được ngay
Chặn module IPsec ESP để vô hiệu hóa đường khai thác hiện biết. Cách này làm ngừng IPsec VPN (strongSwan, Libreswan) trên máy đó. Máy đang dùng IPsec thì phải xin lịch reboot sớm nhất. Sau khi chạy kernel đã vá có thể xóa file cấu hình này.

printf 'install esp4 /bin/false\ninstall esp6 /bin/false\n' | sudo tee /etc/modprobe.d/disable-esp-cve-2026-46300.conf
sudo rmmod esp6 esp4 2>/dev/null; lsmod | grep -E '^(esp4|esp6) ' || echo "Đã chặn"
Copy
2.3 · Kiểm tra dấu hiệu xâm nhập (trước khi reboot)
Máy không dùng IPsec mà vẫn nạp module esp4, esp6, espintcp.
Lệnh su lên root mà không hỏi mật khẩu.
Tiến trình web (www-data, nginx, apache, php-fpm) sinh ra shell: xem bằng ps -ef --forest.
Kết nối SSH đi ra ngoài lạ từ server web: sudo ss -tnp state established '( dport = :22 )'.
File hệ thống bị thay đổi so với gói gốc. Lệnh dưới đây đọc file đang nằm trong bộ nhớ, nên phát hiện được thay đổi mà reboot sẽ xóa mất. Chú ý file trong /etc/pam.d/, /usr/bin/, /usr/sbin/ có số 5 ở cột thứ ba (checksum khác gốc).

# Ubuntu

sudo dpkg --verify 2>/dev/null | grep -E ' /(etc/pam\.d|usr/bin|usr/sbin|bin|sbin)/'

# Amazon Linux

sudo rpm -Va 2>/dev/null | grep -E ' /(etc/pam\.d|usr/bin|usr/sbin|bin|sbin)/'
Copy
Thấy dấu hiệu nào ở trên: không reboot, không xóa gì.
Cô lập máy khỏi Internet (ví dụ đổi Security Group), giữ nguyên trạng thái và báo ngay cho quản lý SBU1 để thu thập bằng chứng.

2.4 · Cập nhật PHP
Máy có PHP cần lên 8.5.12, 8.4.27, 8.3.36 hoặc 8.2.35 trở lên để chặn đường vào ban đầu (PHP2Shell, CVE-2026-109618 và CVE-2026-109619). Vá PHP không thay thế được việc vá kernel.

Bước 3
Ubuntu: giảm rủi ro CVE-2026-98432 trong lúc chờ bản vá
Amazon Linux đã có bản vá: làm bước 2.1 là xong, bỏ qua bước này. Ubuntu chưa có bản vá, nên trong lúc chờ cần làm ba việc dưới đây. Không việc nào thay được bản vá. Theo AWS, chỉ cập nhật kernel và reboot mới xử lý triệt để.

3.1 · Tắt MPTCP
Kịch bản chiếm root đã công bố cần server có socket MPTCP. Rất ít ứng dụng web thực sự cần MPTCP, nên tắt đi gần như không ảnh hưởng. Tắt MPTCP chỉ loại kịch bản đã công bố. Lỗi gốc nằm ở TCP IPv4 nên vẫn kích hoạt được qua các cổng TCP khác, vì vậy cần làm thêm bước 3.2.

echo 'net.mptcp.enabled = 0' | sudo tee /etc/sysctl.d/99-disable-mptcp-cve-2026-98432.conf
sudo sysctl -w net.mptcp.enabled=0

# Restart các dịch vụ còn hiện ở lệnh dưới (socket MPTCP cũ không tự đóng):

sudo ss -Mltnp
Copy
3.2 · Chặn gói tin TCP có IP options
Muốn khai thác lỗi này, kẻ tấn công phải gửi gói TCP có IP options (Record Route, Timestamp). Ứng dụng bình thường gần như không bao giờ gửi loại gói này. Luật dưới đây chặn ở bảng raw, nên áp dụng cho cả cổng do Docker publish. AWS và TuxCare đều khuyến nghị cách này.

Thử trên staging trước khi áp lên production.
Luật mất sau khi reboot. Sau khi máy chạy kernel đã vá thì không cần luật này nữa.

sudo iptables -t raw -I PREROUTING 1 -p tcp -m u32 --u32 '0>>24&0x0f=6:15' -j DROP

# Kiểm tra: dòng đầu tiên phải là luật DROP vừa thêm

sudo iptables -t raw -L PREROUTING -n -v --line-numbers

# Đường kích hoạt thứ hai của lỗi: giá trị này phải là 0

sysctl net.ipv4.tcp_migrate_req

# Gỡ luật khi đã vá xong:

# sudo iptables -t raw -D PREROUTING -p tcp -m u32 --u32 '0>>24&0x0f=6:15' -j DROP

Copy
3.3 · Thu hẹp cổng mở ra Internet
Rà Security Group và firewall: chỉ mở đúng cổng cần thiết. SSH (22) chỉ mở cho IP công ty hoặc VPN, hoặc dùng SSM Session Manager thay SSH.
Máy cần ưu tiên là máy nhận kết nối TCP trực tiếp từ Internet: EC2 có IP public, server sau NLB (TCP), bastion, máy chạy Nginx ở ngoài cùng. Server chỉ nhận kết nối qua ALB hoặc CloudFront thì đã được AWS chặn ở tầng hạ tầng.
Bước 4
Ubuntu: theo dõi và vá CVE-2026-98432 khi có bản vá
Người phụ trách hạ tầng mỗi dự án kiểm tra mỗi ngày bằng lệnh dưới. Khi lệnh báo đã có bản vá thì làm lại bước 2.1 (cập nhật và reboot), rồi gỡ luật ở bước 3.2.

sudo apt update && sudo pro fix --dry-run CVE-2026-98432
Copy
Trang theo dõi chính thức: Ubuntu CVE-2026-98432.

Máy làm việc cá nhân của member
Máy dev giữ SSH key, token Git, thông tin truy cập AWS và tài khoản của khách. Mã độc lọt vào qua gói npm/pip, extension IDE hay repo lạ có thể dùng Fragnesia để lên root mà không cần mật khẩu. Máy cá nhân nằm sau NAT nên ít bị CVE-2026-98432 tấn công trực tiếp từ Internet, nhưng vẫn nên tắt MPTCP vì không tốn gì.

Ubuntu desktop
khoảng 5 phút
Chạy script ở bước 1.
Cập nhật và reboot. Ubuntu thường đã tự cài bản cập nhật nhưng không tự reboot, nên máy để chạy liên tục hàng tuần vẫn chạy kernel cũ.
Tắt MPTCP theo bước 3.1. Không cần luật chặn ở bước 3.2.
sudo apt update && sudo apt full-upgrade -y && sudo reboot
Copy
WSL2 trên Windows
PowerShell
WSL2 dùng kernel của Microsoft. Chạy apt upgrade bên trong Ubuntu WSL không cập nhật kernel. Cập nhật kernel bằng lệnh dưới trong PowerShell, sau đó vẫn chạy apt upgrade trong WSL như bình thường cho các gói khác.

wsl --update
wsl --shutdown
Copy
Mac, hoặc Docker Desktop trên Mac/Windows: không có kernel Linux cần vá trên máy. Chỉ cần cập nhật Docker Desktop lên bản mới nhất.

PM nhắc member trong dự án tự làm, rồi ghi số người đã xong vào dòng "Máy cá nhân member" trong mẫu ở bước 5.

Bước 5
Báo tình trạng trên Teams
Không cần nhập file. Mỗi dự án trả lời một tin trong thread Teams của SBU1: bấm Copy, điền số, đổi icon theo trạng thái rồi gửi. Khi tình trạng thay đổi (ví dụ Ubuntu có bản vá và đã vá xong) thì trả lời thêm một tin mới trong cùng thread.

🟢 Xong
Đã vá hết, hoặc không có máy thuộc diện này.
🟡 Đang làm
Đã giảm thiểu nhưng chưa vá được (ví dụ Ubuntu đang chờ bản vá), hoặc đã có lịch reboot.
🔴 Cần hỗ trợ
Có dấu hiệu xâm nhập, hoặc bị chặn chưa làm được. Có 🔴 thì nhắn ngay, không chờ làm xong các mục khác.
Mẫu (copy và điền)
[Dự án ___] Rà soát Linux kernel
Số máy Linux: **_ (Ubuntu _** · Amazon Linux **_ · khác _**)
🟢 Fragnesia: **_/_** máy đã vá
🟡 CVE-2026-98432: Amazon Linux **_/_** đã vá · Ubuntu **_/_** đã tắt MPTCP + chặn IP options
🟢 Dấu hiệu xâm nhập: không có
🟢 Máy cá nhân member: **_/_** người đã cập nhật
Ghi chú:
Copy
Ví dụ đã điền
[Dự án ABC] Rà soát Linux kernel
Số máy Linux: 6 (Ubuntu 4 · Amazon Linux 2 · khác 0)
🟡 Fragnesia: 5/6 máy đã vá
🟡 CVE-2026-98432: Amazon Linux 2/2 đã vá · Ubuntu 4/4 đã tắt MPTCP + chặn IP options
🟢 Dấu hiệu xâm nhập: không có
🟢 Máy cá nhân member: 7/7 người đã cập nhật
Ghi chú: web-03 (production) xin khách lịch reboot 22:00 ngày 04/11
Danh sách chi tiết từng máy (tên máy, kernel trước và sau) dự án tự giữ để đối chiếu khi cần, không phải gửi.

Thông tin tổng hợp ngày 30/10/2026, cập nhật ngày 02/11/2026. Tình trạng bản vá thay đổi hằng ngày, hãy kiểm tra lại bằng lệnh ở bước 1 và bước 4 trước khi kết luận.

Nguồn tham khảo:

AWS Security Bulletin 2026-160-AWS
TuxCare: CVE-2026-98432 và cách giảm thiểu
BleepingComputer: Fragnesia và PHP2Shell
Ubuntu Security: CVE-2026-98432
Red Hat: CVE-2026-98432
Amazon Linux: CVE-2026-98432
Amazon Linux: CVE-2026-46300
Rescana: Fragnesia và CISA KEV
Phân tích kỹ thuật CVE-2026-98432 và MPTCP
The Hacker News: PwnEscape

Lưu bookmarkĐã lưuĐang lưu…
Beta
AI can make mistakes, so double-check it.
0 / 0
used queries
1
