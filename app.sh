#!/bin/bash
source /etc/profile
app_root=/data/1/usr/local/applications/
#pid_dir=$app_dir/pids/
#mkdir -p $app_dir
#mkdir -p $pid_dir
#cd $app_dir
base_name=""
app_path="" #app根目录
app_name="" #app子项目名称
path=""     #app子项目路径
main=""     #app java main class
args=""     #app java args
jvm=""     #app jvm args
sh=""       #app 启动脚本,该脚本优先级最高,有启动脚本时,直接启动
#command=""  #app 启动命令,该脚本优先级次之,没有启动脚本时,直接调用
start_command=""
start_command_after=""
start_command_before=""
stop_command=""
compile_command=""
compile_command_u=""
nohup="true"
pid_status=""
log="on"
port=""
master_url=""
master_register_url=""
master_upload_url=""

function log(){
	if [ "$log" == "on" ];then
		echo "[`date`] [$1] $2"
	fi
}

#处理系统变量
function parseEnv(){
    file="/data/1/usr/local/sys_env"
	master_url=`grep "master.url=" $file|sed 's/master.url=//g'`
    master_url="http://${master_url}:9003"
    master_register_url="$master_url/app/register?auth_token=f9479ccf304ea4b7c853ef1d3006be67&"
    master_upload_url="$master_url/upload?auth_token=f9479ccf304ea4b7c853ef1d3006be67&"
}
function parse(){

    parseEnv

	pwd=`pwd`
	#log parse $pwd
	app_path=`cd $(dirname $pwd"/"$1);pwd`
	file=$app_path"/"$(basename $pwd"/"$1)

    base_name=$(basename $pwd)
	log "parse" $file
	path=`grep path= $file|sed 's/path=//g'`
	main=`grep main= $file|sed 's/main=//g'`
	args=`grep args= $file|sed 's/args=//g'`
	jvm=`grep jvm= $file|sed 's/jvm=//g'`
	sh=`grep sh= $file|sed 's/sh=//g'`
	start_command_before=`grep start_command_before= $file|sed 's/start_command_before=//g'`
	start_command=`grep start_command= $file|sed 's/start_command=//g'`
	start_command_after=`grep start_command_after= $file|sed 's/start_command_after=//g'`
	stop_command=`grep stop_command= $file|sed 's/stop_command=//g'`
	compile_command=`grep compile_command= $file|sed 's/compile_command=//g'`
	compile_command_u=`grep compile_command_u= $file|sed 's/compile_command_u=//g'`
	nohup=`grep nohup= $file|sed 's/nohup=//g'`
	pid_status=`grep pid_status= $file|sed 's/pid_status=//g'`
	port=`grep port= $file|sed 's/port=//g'`

	app_name=`basename $file|sed 's/launch_//g'|sed 's/\.sh//g'`

	cd $app_path
	mkdir -p $app_path/logs/
	mkdir -p $app_path/pids/
	log "parse" "app_name=$app_name"
	log "parse" "path=$path"
	log "parse" "nohup=$nohup"
	log "parse" "pid_status=$pid_status"
	log "parse" "port=$port"
	log "parse" "sh=$sh"
	log "parse" "$start_command_before=$start_command_before"
	log "parse" "start_command=$start_command"
	log "parse" "start_command_after=$start_command_after"
	log "parse" "stop_command=$stop_command"
	log "parse" "compile_command=$compile_command"
	log "parse" "java main=$main, args=$args, jvm=$jvm"
}
function clone(){

	cd $app_root
	log "clone" "git clone $1 $2"
	git clone $1 $2
	
}

function update(){
	cd $app_path	
	log update 
	git pull
	[ "$path" != "" ] && cd $path
	mvn clean compile
}
function compile(){
        cd $app_path
        log compile
        if [ "$compile_command" != "" ];then
            log "compile" "compile_command $compile_command"
            [ "$path" != "" ] && cd $path
            $compile_command
        else
            log "compile" "mvn clean compile"
            [ "$path" != "" ] && cd $path
            mvn clean compile
            log "compile" "mvn dependency:copy-dependencies"
            mvn dependency:copy-dependencies
        fi

}

function compile-u(){
        cd $app_path
        log compile
        if [ "$compile_command_u" != "" ];then
            log "compile" "compile_command_u $compile_command_u"
            [ "$path" != "" ] && cd $path
            $compile_command_u
        else
            log "compile" "mvn clean compile -U"
            [ "$path" != "" ] && cd $path
            mvn clean compile -U

            log "compile" "mvn dependency:copy-dependencies"
            mvn dependency:copy-dependencies
        fi

}

function tag(){

	log tag "$1 $2"
	git tag -a "$1" -m "$2"
	git push origin "$1"
}

function upgrade(){
	
	log upgrade "$1 $2"
	cd $app_dir/$1
	git fetch $2
}

function status(){

        #cd $app_path

        for r in `ls launch_*.sh`;do
                name=`basename $r|sed 's/launch_//g'|sed 's/\.sh//g'`
        #       echo $name
                pid=0
                log_file=`grep log_file= $r|sed 's/log_file=//g'`

                if [ -f pids/$name ];then
                        pid=`cat pids/$name`

                        c=`ps -ef|awk "{if(\\$2==$pid)print \\$0}"|grep -v grep|wc -l`
                        if [ $c -eq 1 ];then
                                echo "service $name start $log_file"
                        else
                                echo "service $name stop $log_file"
                        fi
                else
                        echo "service $name stop $log_file"
                fi
        done

}
#####程序启动/停止管理
function start(){
	if [ -f "$app_path/pids/$app_name" ];then
		pid=`cat $app_path/pids/$app_name`
    [ "$pid" == "" ] && pid=0
		c=`ps -ef|awk "{if(\\$2==$pid)print \\$0}"|grep -v grep|wc -l`
		if [ $c -eq 1 ];then
			log "start" "pid文件$app_path/pids/$app_name已经存在,并且进程$pid正在运行"
			exit 0
		else
			log "进程信息已经失效$pid进程不存在"
		fi
	fi
	
	
	[ "$path" != "" ] && cd $path
	log "start" "`pwd`"



	if [ "$start_command_before" != "" ];then
        shell "$start_command_before"
	fi


	if [ "$sh" != "" ];then
		$sh
	elif [ "$start_command" != "" ];then
		log "start" "$start_command $start_command"
    #需要兼容多条命令的方式 &&
      #echo "$start_command" |awk -F"&&" '{print $1"\n"$2"\n"$3"\n"$4"\n"$5"\n"$6}'|while read cmd;do
       # if [ "$cmd" != "" ];then
            log "start" "[nohup=$nohup] $cmd "

            if [ "$nohup" == "false" ];then
                  shell "$start_command"
            else
                  nohup $start_command > $app_path/logs/$app_name.log 2>&1 &
            fi
        #fi
     # done
	else
		log "start" "java $jvm -cp target/classes/:target/dependency/* $main $args"
		nohup java $jvm -cp target/classes/:target/dependency/* $main $args > $app_path/logs/$app_name.log 2>&1 &
	fi
	if [ "$pid_status" != "disable" ];then
	    echo $! > $app_path/pids/$app_name
	fi


	if [ "$start_command_after" != "" ];then
        shell "$start_command_after"
	fi

	log start "$app_name已经启动[pid=`cat $app_path/pids/$app_name`]"

	if [ "$port" != "" ];then

	    url="$master_register_url&appName=$base_name&hostName=`hostname`&module=$app_name&clientPort=$port"
	    log "register" "$url"
	fi
	if [ "$1" == "log" ];then
		tail -f $app_path/logs/$app_name.log
	fi
}
function stop(){

  if [ "$stop_command" != "" ];then
		log "stop" "stop_command $stop_command"
		shell "$stop_command"
	elif [ -f $app_path/pids/$app_name ];then
		pid=`cat $app_path/pids/$app_name`
		log "stop" "kill $pid"
		kill $pid
	else
		log "stop" "没有找到pid文件$app_path/pids/$app_name"
	fi

	mater_url=`echo $master_register_url|sed 's/app/app\/remove/g'`
	if [ "$port" != "" ];then

	    url="$mater_url&appName=$base_name&hostName=`hostname`&module=$app_name&clientPort=$port"
	    log "unregister" "$url"
	fi

}

function stop_9(){
	if [ -f $app_path/pids/$app_name ];then
		pid=`cat $app_path/pids/$app_name`
		log "stop" "kill -9 $pid"
		kill -9 $pid
	else
		log "stop" "没有找到pid文件$app_path/pids/$app_name"
	fi
	mater_url=`echo $1|sed 's/app/app\/remove/g'`
	if [ "$port" != "" ];then

	    url="$mater_url&appName=$base_name&hostName=`hostname`&module=$app_name&clientPort=$port"
	    log "unregister" "$url"
	fi
}

function pid(){
	if [ -f "$app_path/pids/$app_name" ];then
                pid=`cat $app_path/pids/$app_name`
                c=`ps -ef|awk "{if(\\$2==$pid)print \\$0}"|grep -v grep|wc -l`
                if [ $c -eq 1 ];then
		#	echo -e "\n\n-------------------------pid---------------------------\n"
			echo -e "\n"
			ps -ef|awk "{if(\$2==$pid)print \$0}"|grep -v grep
			echo  -e "\n"
		#	echo -e "\n-------------------------pid---------------------------\n"
                else
                        log "进程信息已经失效$pid进程不存在"
                fi
        fi
}

function shell(){
  file=".shell_`date +%s`"
  echo "#!/bin/bash" > $file
  echo "$1" >> $file
  chmod +x $file
  ./$file
  rm -rf $file
}

function assembly(){
    log "assembly" "start $app_name"

    #mvn dependency:copy-dependencies
    version="$1"

    if [ "$version" == "" ];then
        version=`git tag|tail -1`
    fi

    pwd=`pwd`
    #app_path=`cd $(dirname $pwd);pwd`
    assemblyFileName=$(basename $pwd|sed 's/test-//g')"@$version.tar.gz"
    baseName=$(basename $pwd|sed 's/test-//g')
    log "app" "$assemblyFileName"
    #assemblyFileName=$(basename |sed 's/test_//g'`-$version.tar.gz"
    assemblyFile=/tmp/$assemblyFileName
    #mkdir $app_path/releases/

    log "assembly" "tar --exclude logs --exclude pids -czf $assemblyFile $baseName"
    mkdir -p /tmp/$baseName
    cp -r ./* /tmp/$baseName/
    cd /tmp/
    tar --exclude logs --exclude pids -czf $assemblyFile $baseName
    log "assembly" "$assemblyFile suc."


    #master_url="$2&fileName=$assemblyFileName"
    log "assembly" "post $master_upload_url&fileName=$assemblyFileName"

    wget  -o /dev/null "$master_upload_url&fileName=$assemblyFileName"  --post-file $assemblyFile  --header="Content-Type:multipart/form-data;boundary=---------------------------7d33a816d302b6"
    rm -rf /tmp/$baseName
    rm -rf $assemblyFile
}
case $1 in
"clone")
	clone $2 $3
	exit 0
	;;
"tag")
	tag $2 $3
	exit 0
	;;
"status")
	log="off"  && status
	exit 0
	;;
esac

#$1 配置脚本
#$2 方法名
case $2 in
"start")
	parse $1 && start "$3"
       ;;
"stop")
	parse $1 && stop
        ;;
"stop_9")
	parse $1 && stop_9
        ;;
"update")
	parse $1 && update
        ;;
"compile")
        parse $1 && compile
        ;;
"compile-u")
        parse $1 && compile-u
        ;;
"pid")
        log="off" && parse $1 && pid
        ;;
"status")
	log="off"  && status
	;;
"tag")
    #tag 版本 注释
	parseEnv && tag $3 $4 && assembly $3
	exit 0
	;;
"assembly")
	parseEnv && assembly $2
	exit 0
	;;
"all")

        parse $1
        git pull
        stop "$3"
        echo -e "\n\n------------------------stop-----------------"
        sleep 2
        echo -e "\n\n------------------------start----------------"
        compile
        start "$3" $4
        ;;
"restart")
	parse $1
	stop "$3"
	echo -e "\n\n------------------------stop-----------------"
	sleep 2
	echo -e "\n\n------------------------start----------------"
	start "$3" $4
        ;;
*)
	echo "只接收参数start|stop|restart|update|compile|pid|status|all|assembly"
	;;
esac
