# k8s-practice
쿠버네티스 클러스터에서 Evicted Pod 된 파드를 자동으로 정리하는 프로젝트

요구 사항
• 일회성 작업 or 특정 주기(cron)로 동작을 선택적으로 컨트롤이 가능
• 1회 동작 후 종료 or 상시 동작을 선택이 가능
• 자동화 작업에 대한 기록을 로그 형태로 기록
• 쿠버네티스 Volume 종류와 상관없이 작업 수행에 대한 로그를 기록
• laC 자동화 도구(Terraform, Ansible, CloudFormation 등)를 활용
