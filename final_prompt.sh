function set_git_username {
   __git_user_email="$(git config user.email 2>/dev/null)"
   __git_user_email_username="${__git_user_email%@*}"
   
   __git_username="${__git_user_email_username:-unset}"    
}
function set_prompt_arguments {
   set_git_username
   __user="\[\e[01;33m\]$__git_username"
   __cur_location="\[\e[01;32m\]\W"
   __git_branch='\[\e[01;31m\]`git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\(\\\\\1\)\ /`'
   __prompt_tail="\[\e[01;35m\]$"
   __last_color="\[\e[01;37m\]"

   __prompt_arguments="$__user $__cur_location $__git_branch$__prompt_tail$__last_color "
}
function write_hypens {
   local cols=$((`tput cols` - 6))
   local line=""
   for i in $(seq 1 $cols); do
       line=$line"-"
   done
   echo $line
}
function set_final_prompt {
   set_prompt_arguments
   failure='\[\e[01\;31m\]✘ $(write_hypens) \:\('
   success='\[\e[01\;32m\]✔ $(write_hypens) \:\)'
   PS1="\`if [ \$? = 0 ]; then echo $success; else echo $failure; fi\`\n$__prompt_arguments"
}

set_final_prompt
