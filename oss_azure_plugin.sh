#!/bin/bash

# oss地址配置
OSS_URL=http://nfvpvx.natappfree.cc
# oss令牌配置
OSS_TOKEN=fb9028b0a8e04a34a874ed491bb3841c

ping -c 3 nfvpvx.natappfree.cc
echo "项目名称:$project_name 构建版本:$(Build.BuildNumber) 当前目录:$(pwd)"
echo [INFO] 

echo "目前项目名称:${project_name##*/}"
echo "结束"
# 打包工作目录
tar -zcvf $project_name.tgz *

# 上传工作目录压缩包
task_data=$(curl --location --request POST -s -k --tlsv1 ''$OSS_URL'/oss/api-v1/open-api/sdl/add' \
 --header 'OpenApiToken: '$OSS_TOKEN'' \
 --form 'file=@"'$project_name'.tgz"' \
 --form 'token='$OSS_TOKEN'' \
 --form 'integrationType=5' \
 --form 'taskName='$project_name'' \
 --form 'version='$build_version'')
echo "任务result:${task_data}"

# 删除工作目录压缩包
rm -rf ${project_name}.tgz

code=$(python -c "import json; print(${task_data}['code'])")
echo ${code}

# 获取并解析检测结果
if [ $code = "0" ];then
	echo "上传检测包成功${code}"
	taskId=$(python -c "import json; print(${task_data}['data'])")
	echo "任务Id:${taskId}"
	while true
	do
		status_data=$(curl --location --request GET -s -k --tlsv1 ''$OSS_URL'/oss/api-v1/open-api/jenkins/task/status/'${taskId}'' \
		--header 'OpenApiToken: '$OSS_TOKEN'')
		echo "获取检测状态result:${status_data}"
		status_code=$(python -c "import json; print(${status_data}['data'])")
		echo "检测状态status_code:${status_code}"
		sleep 3
		if [ $status_code = "2" ];then
			eport_data=$(curl --location --request GET -s -k --tlsv1 ''$OSS_URL'/oss/api-v1/open-api/jenkins/task/statistics/'${taskId}'' \
			--header 'OpenApiToken: '$OSS_TOKEN'')
			echo "获取检测报告result:${eport_data}"
			key_one="data"
			#漏洞
			key_two="vulNumVO"
			result_vul=$(python -c "import json; print(${eport_data}['${key_one}']['${key_two}'])")
			vul_total=$(python -c "import json; print(${result_vul}['total'])")
			vul_serious=$(python -c "import json; print(${result_vul}['serious'])")
			vul_high=$(python -c "import json; print(${result_vul}['high'])")
			vul_medium=$(python -c "import json; print(${result_vul}['medium'])")
			vul_low=$(python -c "import json; print(${result_vul}['low'])")
			vul_normal=$(python -c "import json; print(${result_vul}['normal'])")
			echo "==============漏洞==============="
			echo "漏洞总数："$vul_total
			echo "严重漏洞数："$vul_serious
			echo "高危漏洞数："$vul_high
			echo "中危漏洞数："$vul_medium
			echo "低危漏洞数："$vul_low
			echo "普通漏洞数："$vul_normal
			#组件
			key_two="componentNumVO"
			result_vul=$(python -c "import json; print(${eport_data}['${key_one}']['${key_two}'])")
			cpt_total=$(python -c "import json; print(${result_vul}['total'])")
			cpt_serious=$(python -c "import json; print(${result_vul}['serious'])")
			cpt_high=$(python -c "import json; print(${result_vul}['high'])")
			cpt_medium=$(python -c "import json; print(${result_vul}['medium'])")
			cpt_low=$(python -c "import json; print(${result_vul}['low'])")
			cpt_normal=$(python -c "import json; print(${result_vul}['normal'])")
			echo "==============组件==============="
			echo "组件总数："$cpt_total
			echo "严重组件数："$cpt_serious
			echo "高危组件数："$cpt_high
			echo "中危组件数："$cpt_medium
			echo "低危组件数："$cpt_low
			echo "普通组件数："$cpt_normal
			#许可证
			key_two="licenseNumVO"
			result_vul=$(python -c "import json; print(${eport_data}['${key_one}']['${key_two}'])")
			totalNum=$(python -c "import json; print(${result_vul}['totalNum'])")
			highNum=$(python -c "import json; print(${result_vul}['highNum'])")
			mediumNum=$(python -c "import json; print(${result_vul}['mediumNum'])")
			lowNum=$(python -c "import json; print(${result_vul}['lowNum'])")
			echo "=============许可证==============="
			echo "许可证总数："$totalNum
			echo "高风险数："$highNum
			echo "中风险数："$mediumNum
			echo "低风险数："$lowNum
			if [ $vul_serious = "0" ] && [ $cpt_serious = "0" ] && [ $highNum = "0" ]; then
				echo "=======当前任务检测已通过========"
				exit 0;
			else
				echo "=======由于本次检测存在严重问题,当前任务检测不通过========"
				exit -1
			fi
			break
		fi
	done
else
	echo "上传检测包失败${code}"
	exit -1
fi
