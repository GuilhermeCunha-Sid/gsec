#!/bin/bash

echo    "[-] Hacker Web Tool          [*]"
echo    "[:]--------------------------[:]"
echo    "[1] Sub-Domain Scanner       [*]"
echo    "[2] Domain Directory Scanner [*]"
echo    "[3] Web Scraper              [*]"
echo    "[4] Information Gathering    [*]"
echo    "[5] Trace Router             [*]"
echo    "[:]--------------------------[:]"
read -p "[?] O que deseja fazer: " opt

case $opt in
	1)
		echo "[*] Sub-Domain [*]"
		read -p "[?] Wordlist: " wlist
		read -p "[?] http or https: " http
		read -p "[?] Domain.com: " domain
		read -p "[?] Output File: " outfile

		for i in $(cat $wlist)
		do
			req=$(curl -s --head $http://$i.$domain | cut -d " " -f2 | head -n1)
			case $req in
				"200")
					echo "$http://$i.$domain" >> $outfile
					echo -e "\t\t [200] $i.$domain"
					;;
				*)
					echo "[Tested] $i"
					;;
			esac
		done
		;;
	2)
		echo "[*] Directory Scanner [*]"
		read -p "[?] Wordlist: " wlist
		read -p "[?] URL List: " urllist
		read -p "[?] Output File: " outfile

		for i in $(cat $urllist)
		do
			for d in $(cat $wlist)
			do
				req=$(curl -s --head $i/$d | cut -d " " -f2 | head -n1)
				case $req in
					"200")
						echo "$http://$i/$d" >> $outfile
						echo -e "\t\t [200] $i/$d"
						;;
					*)
						echo "[Tested] $i/$d"
						;;
				esac
			done
		done
		;;
	3)
		echo "[*] Web Scraper [*]"
		read -p "[?] URL List: " urllist
		read -p "[?] Output File: " outfile

		for i in $(cat $urllist)
		do
			echo ""
			echo "[URL] $i"
			echo "==================================="
			echo "[ - ] Verificando Links [ - ]"
			echo ""
				links=$(curl -s $i | grep -Eo 'href="*.*"' | cut -d '"' -f2)
				echo "$links"
				echo "$links" >> $outfile
			echo ""
			echo "[ - ] Verificando Phones [ - ]"
			echo ""
				phone=$(curl -s $i | grep -Eo '[(][0-9]{1,3}[)][ ||][0-9||]{1,3}[ ||][0-9]{1,9}')
				echo "$phone"
				echo "$phone" >> $outfile
			echo ""
			echo "[ - ] Verificando Emails [ - ]"
			echo ""
				emails=$(curl -s $i | grep -Eo '[a-Z0-9._-]*[a-Z0-9]*[@][a-Z0-9]*[.][a-Z0-9]*[.][a-Z0-9||]*')
				echo "$email"
				echo "$email" >> $outfile
		done
		;;
	4)
		read -p "Iniciar Information Gathering [s/N]?" opc
		read -p "[?] Output File: " outfile

		if [[ $opc = "s" || $opc = "S" ]]
		then
		    read -p "Type <Domain.com>: " host
		    echo ""
		    whois=$(whois $host | grep -Eo '^[a-Z].*')
		    echo "$whois" >> $outfile.whois
		    echo "$whois"

		    echo "--------------------------------------------------------------------------"
		    echo "Mapeando Regsitros do Dominio..."
		    lista=['soa','a','aaaa','ns','cname','mx','ptr','hinfo','txt']
		    echo "Executando DNS Scan com os registros: ${lista[*]}"
		    echo ""

		    hostmaster=$(host -t 'soa' $host | grep -o "[a-Z0-9.]*$host[.a-Z0-9]*")
		    ip=$(host -t 'a' $host | grep -o "[a-Z0-9.]*$host[.a-Z0-9]*.\|[0-9].*")
		    ipv6=$(host -t 'aaaa' $host)
		    ns=$(host -t 'ns' $host | grep -o "[a-Z0-9.]*.$host")
		    cname=$(host -t 'cname' $host)
		    mx=$(host -t 'mx' $host | cut -d " " -f7 | cut -d "." -f1,2,3,4)
		    ptr=$(host -t 'ptr' $host)
		    hinfo=$(host -t 'hinfo' $host)
		    vspf=$(host -t 'txt' $host | grep -o "[\"]v=spf[a-Z0-9] include:.*[a-Z0-9][\"]")

		    let i=0
		    for dns in $hostmaster
		    do
		        echo "\"hostmaster$[i=i+1]\":\"$dns\"," >> $outfile.log
		    done

		    domain=$(echo $ip | cut -d " " -f1)
		    dnsaddr=$(echo $ip | cut -d " " -f2)

		    echo "\"dns\":\"$domain\"," >> $outfile.log
		    echo "\"ip\":\"$dnsaddr\"," >> $outfile.log

		    if [[ "$ipv6" == "$host has no AAAA record" ]]
		    then
		        echo "\"ipv6\":\"NoIpv6\"," >> $outfile.log
		    else
		        ipv6=$(echo $ipv6 | cut -d " " -f5)
		        echo "\"ipv6\":\"$ipv6\"," >> $outfile.log
		    fi

		    let i=0
		    for name in $ns
		    do
		        echo "\"NameServer$[i=i+1]\":\"$name\"," >> $outfile.log
		    done

		    let i=0
		    for mail in $mx
		    do
		        echo "\"MailExchange$[i=i+1]\":\"$mail\"," >> $outfile.log
		    done


		    if [[ "$ptr" != "$host has no PTR record" ]]
		    then
		        echo "\"Ptr\":\"$ptr\"," >> $outfile.log
		    fi

		    if [[ "$hinfo" != "$host has no HINFO record" ]]
		    then
		        hinfo=$(host -t 'hinfo' $host | sed 's/\"//g' | cut -d " " -f4-)
		        echo "\"Hinfo\":\"$hinfo\"," >> $outfile.log
		    fi


		    echo "\"VSFP\":$vspf," >> $outfile.log
		    host -t 'txt' $host | grep -o "[\"].*[\"]" | sed 's/^/"Text":/g' | sed 's/$/,/g' >> $outfile.log

		    let i=0
		    for nameserver in $ns
		    do
		        dns=$(host -l -a $host $nameserver | grep -o  "[a-z0-9]*[.]$host" | sort -u | sed 's/^/"/g' | sed 's/$/",/g')
		        for address in $dns
		        do
		            echo "\"dns$[i=i+1]\":$address" >> $outfile.log
		        done
		    done

		    jparser=$(cat $outfile.log | sed '1i{' | sed '$a}')
		    echo $jparser > $outfile.log
		    cat $outfile.log
		fi
		;;
	5)
		echo "[*] Trace Router             [*]"
		read -p "[?] Digite o <domain.com>: " domain

		c=1
        	while [[ c ]]
        	do
                	req=$(hping3 -1 -t $c -c 1 $domain 2> /dev/null | tail -n1)
                	if [[ "$(echo $req | cut -d " " -f1,2)" == "TTL 0" ]]
                	then
                        	echo -n "$c - "
                        	echo $req | cut -d " " -f6
                	elif [[ "$(echo $req | cut -d" " -f1)" == "HPING" ]]
                	then
                        	echo "$c - * * *"
                	else
                        	echo -n "$c * "
                        	echo $req | cut -d " " -f2,3,6
                        	break
                	fi

                	(( c = c +1 ))
        	done
		;;
	*)
		echo "Opção Invalida. Finalizando o Programa!"
		;;
esac

