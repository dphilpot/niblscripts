; NIBL - Bot search.
; This script pulls it's information from NIBL's website.
;           
;
; Usage:    /nibl [search terms]
;           
; Examples: Open the NIBL Search dialog:        /nibl
;           Opens dialog and sets search text:  /nibl some show
;           To cancel an auto-retry attempt:    /cancelget Botname.#PackNumber
;            
; Creator:  Hanzo (@Rizon)  /  Rand (@DALnet)  /  Rand#0001 (@Discord)
; Version:  1.0
;
; Requires: The below are already included, but I'm listing them as these were not made by me.  
;           See note below as to why I'm including them.
;
;           JSON For mIRC.    (We use this to grab the JSON and return the results.)
;           GitHub location: https://github.com/SReject/JSON-For-Mirc 
;           Download Link as of 23rd March 2018:  https://github.com/SReject/JSON-For-Mirc/releases/download/v1.0.4000/JSONFormIRC-v1.0.4000.mrc
;
;           MDX.              (We use this to change our List control into a ListView control, for columns.)
;           Download Link as of 27th March 2018:  http://westor.ucoz.com/load/mirc_dlls/mdx/2-1-0-5
;           
;           - I have included a copy of these with this script, IRC is dying off and scripts/dlls are starting
;             to disappear.  Normally I prefer to let people get the required scripts themselves, but 
;             will be including them for this and any future mIRC Scripts that I make.
;
;
;        
;         Changelog:
;           1.0 - Switched over from using sockets to SReject's JSON for mIRC script.
;                 Created a dialog, now you can use a simple interface for searching.
;                 This required doing a rewrite for the majority of the code.
;
;           -.- - Skipped a bunch of versions, due to a large redesign.
;                 
;           0.3 - Added a "Retry" option - for incomplete downloads.  On by default.
;                 You can /cancelget Botname.#PackNumber, to cancel a specific retry attempt.
;           0.2 - Added a "Trust" bot option - auto accepts downloads only from bots you
;                 requested a file from.
;           0.1 - Initial release.
;
;         TO-DO:
;           + Add functionality to < and > buttons once the API is updated!


;  The Command to open the dialog.
alias nibl { 
  set %niblget.dialog.search $1- 
  dialog -m niblget niblget
}

;  The Dialog.
dialog niblget {
  title "NIBL Search (v1.0)"
  size -1 -1 812 452
  option pixels
  box "Results:", 1, 4 64 800 351
  list 2, 16 85 775 292, size extsel
  button "Close", 3, 700 419 104 25
  box "Search:", 4, 4 4 800 56
  combo 5, 492 26 189 234, drop
  text "Search:", 6, 16 28 42 17
  edit "", 7, 62 26 250 20
  text "Bot:", 8, 462 28 26 17
  button "Get File", 9, 355 380 97 25
  button "Refresh Bot List", 10, 685 24 104 25
  button "Search", 11, 314 24 105 25, default
  check "Trust Bots", 12, 5 423 74 17
  check "Retry DL if incomplete.", 13, 81 423 136 17
  text "", 14, 227 425 342 17
  button "<", 15, 16 379 65 25
  button ">", 16, 726 379 65 25
}



;
; Initializing the dialog.
;
on *:dialog:niblget:init:*: {
  ; MDX Shenanigans so we can have a "ListView" control. (turns List into ListView).
  mdxinit
  mdx SetControlMDX $dname 2 ListView report rowselect grid > $mdx_views
  ;mdx SetColor $dname 2 background $rgb(100,200,75)
  did -i $dname 2 1 headerdims 125 500 80 50
  did -i $dname 2 1 headertext Bot Name $chr(9) File $chr(9) Pack $chr(9) Size
  ; Checkmark heckmark the checkboxes if required.
  did -a niblget 5 All
  did -a niblget 5 Latest Packs
  if (%niblget.dialog.trust) {
    did -c $dname 12
  }
  if (%niblget.dialog.retry) {
    did -c $dname 13
  }
  ; Use the JSON For mIRC script to pull the bots.
  jsonopen -du nibl https://api.nibl.co.uk:8080/nibl/bots
  noop $jsonforeach($json(nibl,content), _addBotsToNIBLGET)
  did -c $dname 5 1
  did -f $dname 7

  did -a $dname 7 %niblget.dialog.search
}


;
; JSON ForEach Loop aliases.
; These get triggered by $jsonforeach
; and populate the Dialog's "ListView" control with files, and drop down with bot names.
;
alias _addBotsToNIBLGET {
  did -a niblget 5 $json($1-,name).value
  hadd -m niblBotList $json($1-,id).value $json($1-,name).value
}
alias _addFilesToNIBLGET {
  did -a niblget 2 $hget(niblBotList,$json($1-,botId).value) $chr(9) $json($1-,name).value $chr(9) $chr(35) $+ $json($1-,number).value $chr(9) $+([,$json($1-,size).value,])
}


;
; Click Search button.
;
on *:dialog:niblget:sclick:11: {
  var %ctime = $ctime
  did -r niblget 2
  ;14 original id
  did -a $dname 1 "Searching..."
  ; Check to see if we are searching for the Latest Packs, or if it's a normal search.
  if ($did($dname,5) == Latest Packs) {
    jsonopen -du test https://api.nibl.co.uk:8080/nibl/latest?size=50
    noop $jsonforeach($json(test,content), _addFilesToNIBLGET)
  }
  else {
    var %search = $regsubex($did(niblget,7),/([^A-Za-z0-9])/g,% $+ $base($asc(\t),10,16))
    var %botid
    if ($did($dname,5) != All && $did($dname,5) != Latest) {
      var %botid = / $+ $hfind(niblBotList,$did($dname,5)).data
    }
    jsonopen -du test https://api.nibl.co.uk:8080/nibl/search $+ %botid $+ ?query= $+ %search $+ &episodeNumber=-1
    noop $jsonforeach($json(test,content), _addFilesToNIBLGET)
  }
  did -a $dname 1 $calc($did($dname,2).lines - 1)) Results in: $duration($calc($ctime - %ctime)) -- Page: 1 / 1 --
}



on *:dialog:niblget:sclick:12: {
  set %niblget.dialog.trust $did($dname,12).state
}
on *:dialog:niblget:sclick:13: {
  set %niblget.dialog.retry $did($dname,13).state
}

on *:dialog:niblget:sclick:5: {
  var %t = $did($dname,5)
  if (%t == Latest Packs) {
    did -r $dname 7
    did -b $dname 7
  }
  else {
    did -e $dname 7
  }
}

; Click Close
on *:dialog:niblget:sclick:3: {
  dialog -x $dname
}


; Download Files
on *:dialog:niblget:sclick:9: {

  if ($network != Rizon) {
    did -a $dname 14 ERROR:  Make sure your active Network is Rizon and try again.
    return
  }

  var %i = $did($dname,2,0).sel
  while (%i) {
    var %t = $did($dname,2,$did($dname,2,%i).sel)
    if ($regex(%t,/\s\+f?s 0 0 0(.+?)(?=\s\+f?s 0 0 0|$)/g)) {
      .timer 1 $calc(%i * 5) _getpack $regml(1) $regml(3) $regml(2)
    }
    dec %i
  }
}




;  Directory locations, mostly for MDX related stuff.
alias nibldir { return $scriptdir }
alias mdx_fulldir { return $+($nibldir,includedRequirements\mdxstudio\) }
alias mdx_fullpath { return $+(",$nibldir,includedRequirements\mdxstudio\mdx.dll,") }
alias mdx_views { return $+($mdx_fulldir,views.mdx) }
alias mdx_bars { return $+($mdx_fulldir,bars.mdx) }
alias mdx_ctl_gen { return $+($mdx_fulldir,ctl_gen.mdx) }
alias mdx_dialog { return $+($mdx_fulldir,dialog.mdx) }

alias mdx { dll $mdx_fullpath $1- }

alias mdxinit {
  dll $mdx_fullpath SetMircVersion $version
  dll $mdx_fullpath MarkDialog $dname
}

; Get a pack from a bot.
; /_getPack nickname packnumber filehere
alias _getPack {
  var %nick = $1 , %pack = $2 , %file = $3- , %np = $+(%nick,.,%pack)
  if (%niblget.dialog.trust) {
    .dcc trust $address(%nick,3)
  }
  echo -s 4> 5Fetching:4 %file     5From:4 %nick     5Pack:04 %pack
  .msg %nick xdcc send %pack
  hadd -m niblget %np %file
}


; If the pack fails to download, then try to requeue it.
on *:getfail:*:{
  if (!%niblget.dialog.retry) return
  var %n = niblget , %f = $nopath($filename) , %nickwm = $nick $+ .*
  if ($hfind(%n,%f,1).data != $null) {
    var %np = $v1
    if (%nickwm iswm %np) {
      if ($regex(%np,/^(.+?)\.(#.+?)$/)) {
        echo -s Failure to get file from $regml(1), and requesting the file (pack $regml(2) ) again in 15 seconds.
        echo -s To cancel this, double click the word "CANCELGET" in the line below. Or type: /cancelget %np
        echo -sa 4[CANCELGET]7 %np 5-7 %f     5(auto retry in 15sec)
        beep 1
        .timer. $+ %np 1 15 msg $regml(1) xdcc get $regml(2) 
      }
    }
  }
}


; Cancel the file get
alias cancelget {
  .timer. $+ $1 off
  hdel niblget $1
  echo -a Cancelled retries for $1
}


; Remove the file after completing the download.
on *:filercvd:*:{
  var %n = niblget , %f = $nopath($filename) , %nickwm = $nick $+ .*
  if ($hfind(%n,%f,1).data != $null) {
    var %np = $v1
    if (%nickwm iswm %np) {
      echo -s File recieved.  Removing %np from the watch list.
      hdel niblget %np
    }
  }
}
alias stripFluff { return $regsubex($1-,/\.|-|_/g,$chr(32)) }

; Hotlinks to cancel the auto-retry.
on ^*:hotlink:[CANCELGET]:*:{
  if ($strip($gettok($hotline,1,32)) != [CANCELGET]) halt
  if ($strip($1) == [CANCELGET]) return
  halt
}
on *:hotlink:[CANCELGET]:*:{
  tokenize 32 $hotline
  if ($hget(niblget,$2)) {
    echo -sa 4> 5Removing auto-retry for:07 $2 5-7 $hget(niblget,$2)
    hdel niblget $2
    .timer. $+ $2 off
  }
  else {
    echo -a 4> 5No auto-retry set for:07 $2
  }
}
