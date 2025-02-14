#bin/bash!

#Github @luoxue-bot
#Blog https://ty.al

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
read -r -p "WARP是否已安装? [y/n] " input
if [[ "$input" == "n" ]];then
    curl -sL https://raw.githubusercontent.com/GeorgeXie2333/Project-WARP-Unlock/main/run.sh | bash
elif [[ "$input" == "y" ]];then
    read -r -p "请输入你需要的国家/地区代码(e.g. HK,SG):" area
fi
while [[ "$input" == "y" ]]
do
    result=$(curl --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
    if [[ "$result" == "404" ]];then
        echo -e "检测结果:Originals Only, 正在更换IP..."
	systemctl restart wg-quick@wg
        sleep 5
	
    elif  [[ "$result" == "403" ]];then
        echo -e "检测结果:No, 正在更换IP..."
        systemctl restart wg-quick@wg
        sleep 5
	
    elif  [[ "$result" == "200" ]];then
		region=`tr [:lower:] [:upper:] <<< $(curl --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
		if [[ ! "$region" ]];then
			region="US";
		fi
        if [[ "$region" != "$area" ]];then
            echo -e "Netflix Region: ${region} 并非需要的地区, 正在更换IP..."
            systemctl restart wg-quick@wg
        sleep 5
        else
            echo -e "Netflix Region: ${region} 成功, 监控中...5分钟后将再次检测"
            sleep 300
        fi

    elif  [[ "$result" == "000" ]];then
	echo -e "失败，正在重试..."
        systemctl restart wg-quick@wg
        sleep 5
    fi
done
