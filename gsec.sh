#!/bin/bash

echo    "[-] Hacker Web Tool          [*]"
echo    "[:]--------------------------[:]"
echo    "[1] Sub-Domain Scanner       [*]"
echo    "[2] Domain Directory Scanner [*]"
echo    "[3] Web Scraper              [*]"
echo    "[:]--------------------------[:]"
read -p "[?] O que deseja fazer: " opt
read -p "[?] Output File: " outfile

case $opt in
	1)
		echo "[*] Sub-Domain [*]"
		read -p "[?] Wordlist: " wlist
		read -p "[?] http or https: " http
		read -p "[?] Domain.com: " domain
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
	*)
		;;
esac

