#!/bin/bash #run.bash
#xh bash based scraper
function rmdotes() {
#https://es.xhamster.com/photos/gallery/some-gallery-12345678/5 #expectedinput
url=$(echo $url|sed 's_https://es._https://_') #si es el espanyol borra el es. 
#https://xhamster.com/photos/gallery/some-gallery-12345678/5 #expectedoutput
}
function deletepagenumberfromurl() {
#https://xhamster.com/photos/gallery/some-gallery-12345678/5 #expectedinput
slashes=$(echo $url|tr -cd / |wc -c) #number of slashes in $url #cuenta la cantidad de / que hay en $url
if [ $slashes -eq 6 ];	# si hay 6 $slashes	
then			#entonces
url=${url%/*}		#borra lo que esta despues del ultimo /
fi			#fin
#https://xhamster.com/photos/gallery/some-gallery-12345678 #expectedoutput
}
function pagedl() {
#url #expectedinput
curl -s "$1" #funcion para descargar una pagina
#html file #expectedoutput
}
function getinitials() {
#everything in html file #expectedinput
pagedl "$1" | \grep 'window.initials'    #busca la linea donde estan las imagenes 
#just line that starts with "window.initials" #expectedoutput
}
function getpretty() {
#html initials #expectedinput
getinitials "$1"| sed -E 's_\{|\,|\}_\n&\n_g' #embellecer initials
#initials separados en lineas # expectedoutput
#tr '\n' ' ' # reemplaza newlines por espacios , lo contrario que hace esta funcion
}
function getphotolinks() {
#initials separados en lineas #expectedinput
getpretty "$1" | grep "imageURL" | sed -e 's_\"imageURL\"\:\"__' -e 's_,__' -e 's_"__' -e 's/\\//g' 
#elimina los "imageURL":" del inicio       #elimina los ", del final   			#desescapa los url
#image links #expectedoutput
}
function maxpgsnumber() {
#initials embellecidos #expectedinput
getpretty "$1" | grep "maxPages" | tail --lines=1 | sed 's_\"maxPages\"\:__'  #determines max number of pages
#number of pages #expectedoutput
}
function makelistofpagestodownload() {
#https://xhamster.com/photos/gallery/some-gallery-1234567890 #expectedinput
local mxpgs=$(maxpgsnumber "$1")
#this makes a list of pages numbered from page 1 to $maxpages preceded by url of course
echo "$url"		#puts the first url who doesn't need /n (slash number)
for i in $(seq 2 $mxpgs)	#for the rest of page numbers (2 to maxpages)
	do
		echo "$url/$i"		#put the slash and page number after the url
	done
#https://xhamster.com/photos/gallery/some-gallery-1234567890 #expectedoutput
#https://xhamster.com/photos/gallery/some-gallery-1234567890/2 #expectedoutput
#https://xhamster.com/photos/gallery/some-gallery-1234567890/3 #expectedoutput
}
function getphotoalbum() {
#get list of pages(the entire album) for the given url and filter the photo links from the html
#https://xhamster.com/photos/gallery/some-gallery-1234567890 #expectedinput
#https://xhamster.com/photos/gallery/some-gallery-1234567890/2 #expectedinput
#get list of pages(get the entire album) for the given url and filter the photo links from the html
local listofpages=$(makelistofpagestodownload "$1")
echo "$listofpages"
for line in $listofpages
	do
		getphotolinks $line
	done
#imagelinks for every input pages # expectedoutput
}
function downloadalbum() {
echo "starting download"
#set -x
local galleryid=$(echo "$1" | cut -f6 -d "/")
local fol=$(echo "$PWD/imgs/$usr/$galleryid") #folder path #TODO delete gallery name from folder and move it to the filename
[ -d "$fol" ] || mkdir -p "$fol"    #si existe $fol, nada, caso contrario mkdir $fol
echo "$fol"
#imagelinks #expectedinput
echo "downloading"
getphotoalbum $1 | xargs --max-args=1 --max-procs=8 wget -nv --directory-prefix="$fol" && echo "done"
#set +x
#--spider simula -nv menos output 
#convierte el stream en parametros para wget y wget los descarga
#$PWD/$usr/galleryid/*(.jpg|.gif) #expectedoutput 
}
function getuserpagessequence() {
local mxpgs=$(getpretty "$1"|grep maxPhotoPages|sed s_\"maxPhotoPages\"\:__) #get max number of pages in user gallery
echo "$url"		#puts the first url who doesn't need /n (slash number)
for i in $(seq 2 $mxpgs)	#for the rest of page numbers (2 to maxpages)
	do
		echo "$url/$i"		#put the slash and page number after the url
	done ; }
function filterusergallerylinks() {
local listofpages=$(getuserpagessequence "$1")
for line in $listofpages
	do
	getinitials "$line" \
	| grep -o 'userGalleriesCollection.*favoritesGalleryCollection' | sed -e 's_{_\n{_g' | grep "\"secure\":0" | sed -e 's_\,_\n\,_g' | grep "pageURL" | sed -e 's_.*\"\:\"__' -e 's_\\__g' -e 's_\"__'
	done; }
function editusergalleries() {
#get user gallery links for all pages and put them in a temporary file and open it to edit
#not yet implemented
#TODO user galleries selector, discriminator
#TODO make_list_of_galleries_from_user()
filterusergallerylinks "$1"; }

function treatitlikeauserbook() {
echo "$1 <xhamster user book>"
url="$1"
url=$(echo $url|sed 's_https://es._https://_') #si es el espanyol borra el es. 
deletepagenumberfromurl
echo "getting user galleries to filter what you like"
usr=$(getinitials "$1"|grep -Po 'verified\".*\"status\"'|cut -f2 -d ","|cut -f4 -d \")
echo "$usr"
usergallerylist=$(editusergalleries "$url")
echo "$usergallerylist"
#TODO logic to download more than one page of a gallery at the same time
for url in $usergallerylist
	do
		downloadalbum "$url"	
		echo "downloading $url"
	done
echo "job done"; }
function treatitlikeasinglegallery() {
echo "$1 <gallery>"
url="$1"
rmdotes
deletepagenumberfromurl
usr=$(getinitials "$url" | \grep -Po 'authorModel.*relatedQuery' | \grep -Po 'name.*}'| sed 's_name":"__'|sed 's_"}__') 
echo \$user:"$usr"
echo "something"
downloadalbum  "$url"
#TODO calculate_space_needed_for_gallery() { probably needs to make a dry run from wget }
echo "done" ; }
function treatitlikeafile() {
#take a filename as argument , read links inside , and pass to argumenthandle to define what type of links they are
echo "$1 <file>"
local input="$1"
while IFS= read -r line
do
	line=$(echo "$line"|sed 's_#.*$__'|grep .) #sed borra comments, grep borra espacios
	echo "$line"
	#bash run.bash "$line" 
done < "$input" ; }
function linkxhamsterhandle() {
#logic to define if argument is a user-gallery or a single-gallery
if [[ "$1" == "https://"*"xhamster.com/users/"*"/photos"* ]] #if user-gallery  #TODO second * could be matched as nothing, we want at least something
then
echo user-gallery ; treatitlikeauserbook "$1" 
elif [[ "$1" == "https://"*"xhamster.com/photos/gallery/"* ]] # # if single gallery
then
echo single-gallery ; treatitlikeasinglegallery "$1"
else
echo "looks like a xhamster link, but cannot be yet handled"
fi ; }
function argumenthandle() {
#logic to define argument type
if [[ "$1" == "https://"*"xhamster.com/"* ]];then #if xhamster link
	linkxhamsterhandle "$1"
elif [ -f "$1" ];then #if file
	treatitlikeafile "$1"
else
	echo "$1 <trash argument>"
fi ; }

for arg in "$@"
do
argumenthandle "$arg"
done

#TODO index file that notes 
#	filename , original tags , url , custom tags , inode , shasum
