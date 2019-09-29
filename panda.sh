#!/bin/bash

cur_work_dir=


initialize_env()
{
    cur_work_dir=$PWD
}

execute_command()
{

    return 0
}

create_merge_request()
{
    return 0
}

update_merge_request()
{
    return 0
}

close_merge_request()
{
    return 0
}

reopen_merge_request()
{
    return 0
}

get_local_branch()
{
    return 0
}

get_remote_branch()
{
    return 0
}

show_merge_diff()
{
    return 0
}

get_new_merge_info()
{
    return 0
}

get_merge_to_update()
{
    return 0
}

get_merge_to_close()
{
    return 0
}

get_merge_to_reopen()
{
    return 0
}

main()
{
    local user_cmd=$1
    case $user_cmd in 
        (create_merge|update_merge|close_merge|repen_merge)
            execute_command "$@"
            ;;
        (help|*)
            print_help
            ;;
    esac
}



