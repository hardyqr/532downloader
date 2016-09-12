# 2016/6/19
# v1.0
#
# 532movie资源下载器
# 使用平台linux/mac
# 参数：电影播放页面网址
#
# 支持断点续传
#
cur_path=pwd
#
# 初始化工作目录
#
if [ -d "$cur_path/532movie_dl/" ]
then
	echo "home dir $cur_path/532movie_dl/"
else
	echo "init home dir $cur_path/532movie_dl/"
	mkdir -p $cur_path/532movie_dl/
fi
#
#
#
cur_path=$cur_path/532movie_dl/
#
#下载用户指定页面
#
html=`echo $1|grep -oE '[^/]+.html'|awk '{print $0}'` 
if [ -f ${cur_path}${html}".ts" ]
then
    echo "has already existed ${cur_path}${html}.ts"
	exit 0
fi

if [ -f "${cur_path}${html}" ]
then 
	echo "${cur_path}${html} has downloaded."
else
	echo "downloading... ${cur_path}${html}"
	curl $1 > ${cur_path}${html}
fi 
#
#分析页面内容，下载资源列表
#

cat ${cur_path}${html}|perl -nle 'print $& if m{(?<=\$playlist=").*(?=")}'|perl -nle 'print $& if m{[^"]*}' > ${cur_path}${html}".linklist"
list=$(<${cur_path}${html}".linklist")
echo -e "${list//"+++"/\n}" > ${cur_path}${html}".linklist"

for line in $(<${cur_path}${html}".linklist")
do 
	if [ -f ${cur_path}${line} ]
	then
		echo "${cur_path}${line}""wl.m3u8 has downloaded."
	#echo ${cur_path}${line}|grep -oP '.*(?=wl)'
	else
		echo ${cur_path}${line}|grep -oE '.*/'
		mkdir -m 775 -p `echo ${cur_path}${line}|grep -oE '.*/'|awk '{print $0}'`
		curl "http://532movie.bnu.edu.cn/"$line > ${cur_path}${line}
	fi
done
#
#下载切片资源
#
for line in $(<${cur_path}${html}".linklist")
do 
	movie_path=`echo ${line}|grep -oE '.*/'|awk '{print $0}'`
	for part in $(<${cur_path}${line})
	do
		if [ "#" = "`echo ${part}|grep -oE '#'|awk '{print $0}'`" ]
		then
			echo $part
		else			
			if [ -f ${cur_path}${movie_path}${part} ]
			then
				echo "${cur_path}${movie_path}${part} has downloaded."
			else
				curl "http://172.16.181.55:6081/"${movie_path}${part} > ${cur_path}${movie_path}${part}
				if [ -f ${cur_path}${movie_path}${part} ]
				then
					echo "OK ${cur_path}${movie_path}${part}"
				else
					curl "http://172.16.181.55:5320/"${movie_path}${part} >> ${cur_path}${movie_path}${part}
				fi
			fi
		fi
	done
done
#
#合成完整电影
#
if [ -f ${cur_path}${html}".ts" ]
then
	echo "${cur_path}${html}.ts has existed. If you want to combine a new movie, please delete the old one first!"
else
	for line in $(<${cur_path}${html}".linklist")
	do 
		movie_path=`echo ${line}|grep -oE '.*/'|awk '{print $0}'`
		for part in $(<${cur_path}${line})
		do
		if [ -f ${cur_path}${movie_path}${part} ]
		then
			cat ${cur_path}${movie_path}${part} >> ${cur_path}${html}".ts"
			echo "OK combine ${cur_path}${movie_path}${part}"
		else
			if [ ! "#" = "`echo ${part}|grep -oE '#'|awk '{print $0}'`" ]
			then			
				echo "!!!---${movie_path}${part}lost---!!!"
			fi	
		fi
		done
	done
fi
#
#删除缓存文件
#
if [ -d ${cur_path}"/uploads/" ]
then
	rm -rf ${cur_path}"/uploads/"
	rm -f ${cur_path}${html}
	rm -f ${cur_path}${html}".linklist"

fi

#end
