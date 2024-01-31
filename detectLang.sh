#!/bin/sh

_usage(){
    echo "============================================================================================================================="
    echo "Usage: "
    echo "    sh -x detectLang.sh --app|-app <Qwiet_App_Name> --path|-path <Directory_to_scan> --token|-token <SHIFTLEFT_ACCESS_TOKEN> "
    echo "    Example: sh -x detectLang.sh --app TestAppQwiet --path /home/jenkins/git/myRepo --token <SHIFTLEFT_ACCESS_TOKEN>         "
    echo "============================================================================================================================="
}

OPTIONS=$@
TOTAL_OPTIONS=$#
INT=0



while [ $TOTAL_OPTIONS -gt $INT ]
do
        case $(OPTIONS[$INT]) in

                --app | -app)
                        INT=`expr $INT + 1`
                        appName=${OPTIONS[$INT]}
                        ;;

                --path | -path)
                        INT=`expr $INT + 1`
                        path=${OPTIONS[$INT]}
                        ;;


                --token | -token)
                        INT=`expr $INT + 1`
                        token=${OPTIONS[$INT]}
                        ;;

                --help | -help | -h)
                        _usage
                        exit 0
                        ;;

                *)
                        echo "Invalid Option - ${OPTIONS[$INT]}"
                        _usage
                        exit 1
                        ;;

        esac
        INT=`expr $INT + 1`
done

export SHIFTLEFT_ACCESS_TOKEN=$token

HIDDEN_DIR=$(ls -a $path | grep '.git')
#if [[ $HIDDEN_DIR == *".git"* ]]; then
if [[ ! $HIDDEN_DIR ]]; then
  git init 2> /dev/null > /dev/null
  git config user.name "githubtest"
  git add --all 2> /dev/null > /dev/null
  git commit -m "local linguist auto commit" 2> /dev/null > /dev/null
fi

if [[ $path == "." ]]; then
    path=$(pwd)
fi

docker run --platform linux/amd64 --rm -v $path:$path -w $path -t shiftleft/lang-detect:latest github-linguist $path --json | jq . > out.json

json=$(cat out.json)
languages=$(echo "$json" | jq  -r 'keys[]' )
for lang in $languages; do

    case $lang in
        Java)
            SHIFTLEFT_SBOM_GENERATOR=2 sl analyze --app $appName-$lang --tag app.group=$appName --javasrc $path
            ;;
        Scala)
            SHIFTLEFT_SBOM_GENERATOR=2 sl analyze --app $appName-$lang --tag app.group=$appName --javasrc $path
            ;;
        Python)
            sl analyze --app $appName-$lang --tag app.group=$appName --pythonsrc $path
            ;;
        JavaScript)
            SHIFTLEFT_SBOM_GENERATOR=2 sl analyze --app $appName-$lang --tag app.group=$appName --js $path
            ;;
        TypeScript)
            SHIFTLEFT_SBOM_GENERATOR=2 sl analyze --app $appName-$lang --tag app.group=$appName --js $path -- --ts
            ;;
        C#)
            sl analyze --app $appName-$lang --tag app.group=$appName --csharp $path
            ;;
        PHP)
            sl analyze --app $appName-$lang --tag app.group=$appName --php $path
            ;;
        Go)
            sl analyze --app $appName-$lang --tag app.group=$appName --go $path
            ;;
        C)
            sl analyze --app $appName-$lang --tag app.group=$appName --c $path
            ;;
        Kotlin)
            sl analyze --app $appName-$lang --tag app.group=$appName --kotlin $path
            ;;
        HCL)
            sl analyze --app $appName-$lang --tag app.group=$appName --checkov $path
            ;;
        *) Echo "Also Found: " $lang ;;
    esac

done
