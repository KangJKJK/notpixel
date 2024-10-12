#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

echo -e "${GREEN}NotPixel 텔레그램 봇을 설치합니다.${NC}"
echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"

main() {
    # 사용자에게 선택지를 제공
    read -p "처음부터 새로 설정하시겠습니까? 아니면 기존 설정을 사용하시겠습니까? (n/m으로 답하세요) (new/maintain): " choice

    if [[ "$choice" == "n" ]]; then
        # 새로 설정하는 로직
        echo "새로 설정을 시작합니다."
        # ... 새로 설정 코드 ...
        # 파이썬 및 필요한 패키지 설치
        echo -e "${YELLOW}시스템 업데이트 및 필수 패키지 설치 중...${NC}"
        rm -rf /root/NotPixel
        sudo apt update
        sudo apt install -y python3 python3-pip git

        # GitHub에서 코드 복사
        echo -e "${YELLOW}GitHub에서 코드 복사 중...${NC}"
        git clone https://github.com/Freddywhest/NotPixel.git

        # 작업 공간 생성 및 이동
        echo -e "${YELLOW}작업 공간 이동 중...${NC}"
        cd /root/NotPixel
        pip3 install -r requirements.txt
        npm install
        cp .env-example .env

        # Node.js LTS 버전 설치 및 사용
        echo -e "${YELLOW}Node.js LTS 버전을 설치하고 설정 중...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # nvm을 로드합니다
        nvm install --lts
        nvm use --lts

        # 사용자에게 query_id 입력 안내
        echo -e "${GREEN}여러개의 NotPixsel를 구동하기 위해서는 각 query_id마다 같은 개수의 프록시가 필요합니다.${NC}"
        echo -e "${GREEN}query_id를 얻는 방법은 텔레그램 그룹방을 참고하세요.${NC}"
        echo -e "${GREEN}여러 개의 query_id를 입력할 경우 줄바꿈으로 구분하세요.${NC}"
        echo -e "${GREEN}입력을 마치려면 엔터를 두 번 누르세요.${NC}"
        echo -e "${YELLOW}query_id를 입력하세요:${NC}"

        query_ids=""
        account_number=1
        echo "{" > /root/NotPixel/bot/queryIds.json
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            query_ids+="$line"$'\n'
            echo "  \"Account$account_number\": \"$line\"," >> /root/NotPixel/bot/queryIds.json
            account_number=$((account_number + 1))
        done

        # 마지막 쉼표 제거
        sed -i '$ s/,$//' /root/NotPixel/bot/queryIds.json
        echo "}" >> /root/NotPixel/bot/queryIds.json

        # 사용자로부터 추가 정보 입력 받기
        read -p "자동 페인트를 사용하시겠습니까? (true/false): " auto_paint
        read -p "자동 청구 작업을 사용하시겠습니까? (true/false): " auto_claim
        read -p "자동 참여 스쿼드를 사용하시겠습니까? (true/false): " auto_join_squad
        read -p "요청 사이의 수면 시간을 입력하세요 (예: [200, 700]): " sleep_between_requests
        read -p "봇 시작 사이의 지연 시간을 입력하세요 (예: [20, 30]): " delay_between_starts
        read -p "페인팅 사이의 지연 시간을 입력하세요 (예: [20, 30]): " delay_between_paintings
        read -p "작업 간 지연 시간을 입력하세요 (예: [20, 30]): " delay_between_tasks

        # JS 파일에서 프록시 사용 설정
        use_proxy_js=true
        use_proxy_txt=false

        # 입력받은 정보를 설정 파일에 반영
        cat <<EOL > .env
{
    "auto_paint": $auto_paint,
    "auto_claim": $auto_claim,
    "auto_join_squad": $auto_join_squad,
    "sleep_between_requests": $sleep_between_requests,
    "delay_between_starts": $delay_between_starts,
    "delay_between_paintings": $delay_between_paintings,
    "delay_between_tasks": $delay_between_tasks,
    "use_proxy_js": $use_proxy_js,
    "use_proxy_txt": $use_proxy_txt
}
EOL

        # 프록시 사용 여부 확인
        echo -e "${YELLOW}프록시를 사용하시겠습니까? (1: 예, 2: 아니오)${NC}"
        read -p "선택: " use_proxy

        if [ "$use_proxy" -eq 1 ]; then
            # 1번 선택시 (프록시 사용)
            echo -e "${RED}프록시의 개수와 query_id 개수가 같아야 합니다.${NC}"
            echo -e "${RED}프록시를 다음 형식으로 입력하세요: http://user:pass@ip:port${NC}"
            echo -e "${RED}챗지피티에게 형식을 알려주면 바꿔줍니다.${NC}"
            echo -e "${RED}여러 개의 프록시를 사용할 경우 줄바꿈으로 구분하세요.${NC}"
            echo -e "${YELLOW}프록시 정보를 입력하시고 엔터를 두번 누르세요:${NC}"
            proxies=""
            while IFS= read -r line; do
                # 빈 줄이 입력되면 종료
                if [ -z "$line" ]; then
                    break
                fi
                proxies+="$line"$'\n'
            done

            # proxies.js 파일에 프록시 정보 추가
            echo "const proxies = [" > root/NotPixel/bot/config/proxies.js
            while IFS= read -r proxy; do

                # 프록시 정보 파싱
                protocol="http"
                user_pass=$(echo $proxy | awk -F[@//] '{print $2}')
                ip_port=$(echo $proxy | awk -F[@] '{print $2}')
                username=$(echo $user_pass | awk -F[:] '{print $1}')
                password=$(echo $user_pass | awk -F[:] '{print $2}')
                ip=$(echo $ip_port | awk -F[:] '{print $1}')
                port=$(echo $ip_port | awk -F[:] '{print $2}')

                # proxies.js 형식에 맞게 작성
                echo "  {" >> root/NotPixel/bot/config/proxies.js
                echo "    ip: \"$ip\"," >> root/NotPixel/bot/config/proxies.js
                echo "    port: $port," >> root/NotPixel/bot/config/proxies.js
                echo "    protocol: \"$protocol\"," >> root/NotPixel/bot/config/proxies.js
                echo "    username: \"$username\"," >> root/NotPixel/bot/config/proxies.js
                echo "    password: \"$password\"" >> root/NotPixel/bot/config/proxies.js
                echo "  }," >> root/NotPixel/bot/config/proxies.js
            done <<< "$proxies"
            echo "];" >> root/NotPixel/bot/config/proxies.js
            echo "module.exports = proxies;" >> root/NotPixel/bot/config/proxies.js

            # 봇 실행
            echo -e "${GREEN}봇을 실행합니다...${NC}"
            cd root/NotPixel
            node index.js

        else
            # 2번 선택시 (프록시 사용 안함)

            # 봇 실행
            echo -e "${GREEN}봇을 실행합니다...${NC}"
            cd root/NotPixel
            node index.js
        fi

    elif [[ "$choice" == "m" ]]; then
        # 기존 설정을 사용하는 로직
        echo "기존 설정을 사용하여 봇을 실행합니다."
        # ... 기존 설정 코드 ...
        cd /root/NotPixel
        node index.js
    else
        echo "잘못된 입력입니다. 'n' 또는 'm'을 입력해주세요."
    fi
}

main