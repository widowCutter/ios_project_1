#!/bin/sh

help()
{
  echo \
' 
 mole -h vypíše tuto nápovědu
  
 mole [-g GROUP] FILE – Zadaný soubor bude otevřen.
 
     Pokud byl zadán přepínač -g, dané otevření souboru bude zároveň přiřazeno do skupiny s názvem GROUP. GROUP může být název jak existující, tak nové skupiny.
 
 mole [-m] [FILTERS] [DIRECTORY] – Pokud DIRECTORY odpovídá existujícímu adresáři, skript z daného adresáře vybere soubor, který má být otevřen.
 
     Pokud nebyl zadán adresář, předpokládá se aktuální adresář.
     Pokud bylo v daném adresáři editováno skriptem více souborů, vybere se soubor, který byl pomocí skriptu otevřen (editován) jako poslední.
     Pokud byl zadán argument -m, tak skript vybere soubor, který byl pomocí skriptu otevřen (editován) nejčastěji.
     Pokud bude při použití přepínače -m nalezeno více souborů se stejným maximálním počtem otevření, může mole vybrat kterýkoliv z nich.
     Výběr souboru může být dále ovlivněn zadanými filtry FILTERS.
     Pokud nebyl v daném adresáři otevřen (editován) ještě žádný soubor, případně žádný soubor nevyhovuje zadaným filtrům, jedná se o chybu.
 
 mole list [FILTERS] [DIRECTORY] – Skript zobrazí seznam souborů, které byly v daném adresáři otevřeny (editovány) pomocí skriptu.
 
     Pokud nebyl zadán adresář, předpokládá se aktuální adresář.
     Seznam souborů může být filtrován pomocí FILTERS.
     Seznam souborů bude lexikograficky seřazen a každý soubor bude uveden na samostatném řádku.
     Každý řádek bude mít formát FILENAME:<INDENT>GROUP_1,GROUP_2,..., kde FILENAME je jméno souboru (i s jeho případnými příponami), <INDENT> je počet mezer potřebných k zarovnání a GROUP_* jsou názvy skupin, u kterých je soubor evidován.
     Seznam skupin bude lexikograficky seřazen.
     Pokud budou skupiny upřesněny pomocí přepínače -g (viz sekce FILTRY), uvažujte při výpisu souborů a skupin pouze záznamy patřící do těchto skupin.
     Pokud soubor nepatří do žádné skupiny, bude namísto seznamu skupin vypsán pouze znak -.
     Minimální počet mezer použitých k zarovnání (INDENT) je jedna. Každý řádek bude zarovnán tak, aby seznam skupin začínal na stejné pozici'
  
}

create_s_log()
{
  while read line
  do
    for dir in $(printf '%s' "$1" | tr , '\n')
    do
      dir=$(realpath $dir)/
      entry=$(printf '%s' "$line" | awk -F ';' '{print $1}')
      if ! [ $(printf '%s' "$dir" | awk -F '/' '{print NF-1}') -eq $(printf '%s' "$entry" | awk -F '/' '{print NF-1}') ]
      then
        continue
      fi
      if printf '%s' "$entry" | grep -q "$dir"
      then
       if [ $matching ]
       then
        matching="${matching}:$line"
        else
        matching="$line"
       fi
      fi
    done
  done < $MOLE_RC
  echo $matching
  
  for n_line in $(printf '%s' "$matching" | tr : '\n')
  do
    dates=$(printf '%s' "$n_line" | awk -F ';' '{print $3}')
    times_open=0
    for date in $(printf '%s' "$dates" | tr , '\n') 
    do
      times_open=$(($times_open+1))
      use=true
      if [ "$MAX_TIME" ]; then
        if ! [ "$date" -le "$MAX_TIME" ]
          then
            use=false
        fi
      fi
      if [ "$MIN_TIME" ]; then
        if ! [ "$date" -ge "$MIN_TIME" ]
          then
            use=false
        fi
      fi
    done
    if $use
    then
      if [ $to_print ]
      then
        to_print="$to_print+$(printf '%s' "$n_line")"
      else
        to_print=$(printf '%s' "$n_line")
      fi
    fi
  done
  echo
  for line_to_format in $(printf '%s' "$to_print" | tr + '\n')
  do
    for date in $(printf '%s' "$to_print" | tr , '\n')
    do
    done
    line_to_print=$(printf '%s' "$line_to_format" | awk -F ';' '{print $1}');
    
    echo $line_to_print
  done
    
  exit 0
}

list()
{
  w_dir=$1/
  local i=1
  while read line
  do
    entry=$(printf '%s' "$line" | awk -F ';' '{print $1}')
    if ! [ $(printf '%s' "$w_dir" | awk -F '/' '{print NF-1}') -eq $(printf '%s' "$entry" | awk -F '/' '{print NF-1}') ]
    then
      continue
    fi
    if printf '%s' "$entry" | grep -q "$w_dir"
    then
     if [ $matching ]
     then
      matching="${matching}:$line"
      else
      matching="$line"
     fi
    fi
    i=$((i+1))
  done < $MOLE_RC
  
  longest_name=0
  for n_line in $(printf '%s' "$matching" | tr : '\n')
  do
    dates=$(printf '%s' "$n_line" | awk -F ';' '{print $3}')
    times_open=0
    for date in $(printf '%s' "$dates" | tr , '\n') 
    do
      times_open=$(($times_open+1))
      use=true
      if [ "$MAX_TIME" ]; then
        if ! [ "$date" -le "$MAX_TIME" ]
          then
            use=false
        fi
      fi
      if [ "$MIN_TIME" ]; then
        if ! [ "$date" -ge "$MIN_TIME" ]
          then
            use=false
        fi
      fi
    done
    g_outer=false
    for group_in in $(printf '%s' "$FGROUPS" | tr , '\n')
    do
      g_inner=false
      for group_entry in $(printf '%s' "$n_line"| awk -F ';' '{print $2}' | tr , '\n')
      do
        g_outer=true
        if [ $group_entry = $group_in ]
        then
          g_inner=true
        fi
      done
      if ! $g_inner
      then
        use=false
      fi
    done
    if ! $g_outer
    then
      use=false
    fi
    if $use
    then
      if [ $to_print ]
      then
        to_print="$to_print+$(printf '%s' "$n_line")"
      else
        to_print=$(printf '%s' "$n_line")
      fi
      if [ $(printf '%s' "$n_line" | awk -F ';' '{print $1}'| awk '{print length}') -gt $longest_name ]
      then
        longest_name=$(printf '%s' "$n_line" | awk -F ';' '{print $1}'| awk '{print length}')
      fi
    fi
  done
  echo
  for line_to_format in $(printf '%s' "$to_print" | tr + '\n')
  do
    line_to_print=$(printf '%s' "$line_to_format" | awk -F ';' '{print $1}')
    
    line_to_print=$(printf '%s' "$line_to_print"):$(printf %"$(($longest_name - $(printf '%s' "$line_to_format" | awk -F ';' '{print $1}'| awk '{print length}')))"s)' '$(printf '%s' "$line_to_format" | awk -F ';' '{print $2}')
    if [ $(printf '%s' "$line_to_format" | awk -F ';' '{print $2}'| awk '{print length}') -le 0 ]
      then
        echo "$line_to_print-"
      else
        echo "$line_to_print"
    fi
      
    
  done
  
  exit 0
}


addFileToList(){
  echo hello
  FILE="$1;$FGROUPS;$(date +%s)"
  echo $FILE >> $MOLE_RC
  sort -f $MOLE_RC -o $MOLE_RC
}

openDir(){
  w_dir=$(realpath $1)/
  echo $w_dir
  local i=1
  while read line
  do
    entry=$(printf '%s' "$line" | awk -F ';' '{print $1}')
    if ! [ $(printf '%s' "$w_dir" | awk -F '/' '{print NF-1}') -eq $(printf '%s' "$entry" | awk -F '/' '{print NF-1}') ]
    then
      continue
    fi
    if printf '%s' "$entry" | grep -q "$w_dir"
    then
     if [ $matching ]
     then
      matching="${matching}:$line"
      else
      matching="$line"
     fi
    fi
    i=$((i+1))
  done < $MOLE_RC
  echo $matching
  
  most_open=0
  to_open=
  last_opened=0
  for n_line in $(printf '%s' "$matching" | tr : '\n')
  do
    dates=$(printf '%s' "$n_line" | awk -F ';' '{print $3}')
    times_open=0
    for date in $(printf '%s' "$dates" | tr , '\n') 
    do
      times_open=$(($times_open+1))
      use=true
      if [ "$MAX_TIME" ]; then
        if ! [ "$date" -le "$MAX_TIME" ]
          then
            use=false
        fi
      fi
      if [ "$MIN_TIME" ]; then
        if ! [ "$date" -ge "$MIN_TIME" ]
          then
            use=false
        fi
      fi
    done
    g_outer=false
    for group_in in $(printf '%s' "$FGROUPS" | tr , '\n')
    do
      g_inner=false
      for group_entry in $(printf '%s' "$n_line"| awk -F ';' '{print $2}' | tr , '\n')
      do
        g_outer=true
        if [ $group_entry = $group_in ]
        then
          g_inner=true
        fi
      done
      if ! $g_inner
      then
        use=false
      fi
    done
    if ! $g_outer
    then
      use=false
    fi
    if $use
    then
      if [ $M ]
      then
        echo "M"
        echo "$n_line times open=$times_open"
        if [ "$times_open" -gt "$most_open" ]
        then
          most_open=$times_open
          to_open=$(printf '%s' "$n_line"| awk -F ';' '{print $1}')
        fi
      else
        for time_opened in $(printf '%s' "$n_line"| awk -F ';' '{print $3}' | tr , '\n')
        do
          if [ "$time_opened" -gt "$last_opened" ]
          then
            last_opened=$time_opened
            to_open=$(printf '%s' "$n_line"| awk -F ';' '{print $1}')
          fi
        done
        echo done
      fi
    fi
  done
  findFileInList $(printf '%s' "$to_open"| awk -F ';' '{print $1}')
  
    
  exit 0
}

addGroupToFile(){
  LINE_N=$1
  LINE_N=$((LINE_N+1))
  ENTRY=$(sed "$LINE_N q;d" $MOLE_RC)

  cur_Entry=$(printf '%s' "$ENTRY" | awk -F ';' '{print $2}')

  for group_in in $(printf '%s' "$FGROUPS" | tr , '\n')
  do
    if ! printf '%s' "$cur_Entry" | grep -q "$group_in"
      then
        cur_Entry="$cur_Entry,$group_in"
    fi
  done
  
  
  printf '%s' "$FGROUPS" | IFS=',' read -r commnad_groups

  
  
  
  sed -i "$LINE_N s/;.*;/;$cur_Entry;/" $MOLE_RC
  sed -i "$LINE_N s/$/,$(date +%s)/" $MOLE_RC
  
  
  return
}


findFileInList(){
  LIST=$(cat $MOLE_RC)
  N_LINE=0
  for line in $LIST; do
    out=$(printf '%s' "$line" | awk -v out="$out" '{sub(/;.*/, ""); print $0}')
    if [ $out = $1 ] 
    then
      addGroupToFile $N_LINE
      return 0
    else
      N_LINE=$((N_LINE+1))
      continue
    fi
  done
  return 1
}

if [ $1 = 'list' ]
then
  OPTIND=2
  elif [ $1 = 'secret-log' ]
  then
  OPTIND=2
fi

while getopts "hmg: b: a: " options; do
  ARGS=$((ARGS+1))
  case "${options}" in
    h)
      help
      exit
      ;;
      
    g)
      ARGS=$((ARGS+1))
      FGROUPS=${OPTARG}
      ;;
    b)
      ARGS=$((ARGS+1))
      MAX_TIME_S=${OPTARG}
      MAX_TIME=$(date +%s -d $MAX_TIME_S)
      if ! [ "$MAX_TIME" ]
      then
        echo 'Wrong date supplied in argument "b"'
        exit 1
      fi
      ;;
    a)
      ARGS=$((ARGS+1))
      MIN_TIME_S=${OPTARG}
      MIN_TIME=$(date +%s -d $MIN_TIME_S)
      if ! [ "$MIN_TIME" ]
      then
        echo 'Wrong date supplied in argument "a"'
        exit 1
      fi
      ;;
    m)
      M=true
      ;;
    *)
      echo "Wrong argument supplied"
      ;;
      
  esac
done

# Check if $MOLE_RC variable is inited and check if file exists. If not create file and directories
# format of file is:
# FILE_PATH;GROUP_1,GROUP_n..,DATE_1(YYYY-MM-DD_HH-mm-ss)
if [ $MOLE_RC ]
  then
    if ! [ -f "$MOLE_RC" ] 
    then
      if [ ! -f $(dirname $MOLE_RC) ] 
      then 
        if ! mkdir -p $(dirname $MOLE_RC)
          then 
            echo "failed to create directory at "$(dirname $MOLE_RC)
        fi
      if ! touch $MOLE_RC
        then 
          echo "file creation at $MOLE_RC failed"
          exit 1
      fi
    fi
  fi
  else
    echo 'Env variable MOLE_RC not set'
    exit 1
fi


if [ $1 = 'secret-log' ]
then
  ARGS=$(($ARGS+1))
  count=$ARGS
  if [ $ARGS -ge "$#" ]
  then
    create_s_log
  else
    for i in $@
    do
      if [ "$count" -le "$(($# - $ARGS - 2))" ]
      then
        echo $i
        if [ $dir_to_log ]
        then
          dir_to_log=$dir_to_log,$i
        else
          dir_to_log=$i
        fi
      fi
      count=$(($count-1))
    done
    if [ -d $i ]
    then
      create_s_log $dir_to_log
    fi
  fi
fi

if [ $1 = 'list' ]
then
  ARGS=$(($ARGS+1))
  if [ $ARGS -ge "$#" ]
  then
    list $(realpath './')
  else
    for i in $@; do :; done
    if [ -d $i ]
    then
      list $(realpath "$i")
    else
      echo "Supplied wrong directory"
      exit 1
    fi
  fi
fi


if [ "$ARGS" -ge "$#" ]
then
  openDir './'
else
  for i in $@; do :; done
  if [ -f $i ]
  then
    echo file exists
    if findFileInList $(realpath "$i")
    then
      echo 'file found in list'
    else
      addFileToList $(realpath "$i")
    fi
  elif [ -d "$i" ]
  then
    openDir $i
  else
    echo "Supplied file or directory doesn't exist"
    exit 1
  fi
  if [ $EDITOR ]
  then
    echo 'exec '$EDITOR '!!debug!!'
  else
    if [ "$VISUAL" ]
      then
        echo 'exec '$VISUAL '!!debug!!'
      else
        echo 'exec vi !!debug!!'
    fi
  fi
fi
