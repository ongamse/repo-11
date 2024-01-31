#!/bin/bash

_usage(){
    echo "============================================================================================================================="
    echo "Usage: "
    echo "    sh -x detectLang.sh --app|-app <Qwiet_App_Name> --path|-path <Directory_to_scan> --token|-token <SHIFTLEFT_ACCESS_TOKEN> "
    echo "    Example: sh -x detectLang.sh --app TestAppQwiet --path /home/jenkins/git/myRepo --token <SHIFTLEFT_ACCESS_TOKEN>         "
    echo "============================================================================================================================="
}

TOTAL_OPTIONS=$#
INT=1

while getopts a:p:t: flag
do 
    case "${flag}" in
        a) appName=${OPTARG};;
        p) path=${OPTARG};;
        t) token=${OPTARG};;
    esac
done

export SHIFTLEFT_ACCESS_TOKEN=$token

HIDDEN_DIR=$(ls -a $path | grep '.git')

if [ -z "${HIDDEN_DIR}" ]; then
  echo "${HIDDEN_DIR} is empty"
  git init 2> /dev/null > /dev/null
  git config user.name "githubtest"
  git add --all 2> /dev/null > /dev/null
  git commit -m "local linguist auto commit" 2> /dev/null > /dev/null
fi

if [ ${path} = "." ];
then
    echo "Path is current dir"
    path=$pwd
fi

docker run --platform linux/amd64 --rm --user $(id -u) -v $path:$path -w $path -t shiftleft/lang-detect:latest github-linguist $path --json | jq . > out.json
export SHIFTLEFT_SBOM_GENERATOR=2

otherLanguages=""

json=$(cat out.json)
languages=$(echo "$json" | jq  -r 'keys[]' )
for lang in $languages; do

    case $lang in
        Java)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --javasrc $path
            ;;
        Scala)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --javasrc $path
            ;;
        Python)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --pythonsrc $path
            ;;
        JavaScript)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --js $path
            ;;
        TypeScript)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --js $path -- --ts
            ;;
        C#)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --csharp $path
            ;;
        PHP)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --php $path
            ;;
        Go)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --go $path
            ;;
        C)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --c $path
            ;;
        Kotlin)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --kotlin $path
            ;;
        HCL)
            ./sl analyze --app $appName-$lang --tag app.group=$appName --checkov $path
            ;;
        *) otherLanguages+=$lang && otherLanguages+=", " ;;
    esac

done

echo "Languages Present that didnt have a Qwiet Scan: " + otherLanguages
