#!/bin/bash

. /home/mike/code/panda/merge.sh
. /home/mike/code/panda/repo.sh
. /home/mike/code/panda/branch.sh

CUR_WORK_DIR=
PANDA_TMP_DIR="/tmp/panda"
MERGE_FILE_SUFFIX=".md"
MERGE_TEMPLATE_FILE=""

initialize_env()
{
    CUR_WORK_DIR=$PWD
}

get_merge_title() {
    return 0
}

get_merge_description() {
    return 0
}

create_merge_request()
{
    local local_branch
    local remote_branch
    local merge_info
    local merge_title
    local merge_desc
    local project_id
    local repo_url
    local repo_name
    local create_result

    repo_url=$(get_remote_repo_url "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get remote repo url failed"
        return 1
    fi

    repo_name=$(get_repo_top_name "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get remote repo name failed"
        return 1
    fi

    project_id=$(get_project_id "${repo_name}" "${repo_url}")
    if [[ $? -ne 0 ]]; then
        echo "get repo(${repo_name}) project id failed"
        return 1
    fi

    local_branch=$(get_local_branch)
    if [[ $? -ne 0 ]]; then
        echo "get local branch failed"
        return 1
    fi

    remote_branch=$(get_remote_branch)
    if [[ $? -ne 0 ]]; then
        echo "get remote branch failed"
        return 1
    fi

    show_merge_diff  "${local_branch}" "${remote_branch}"
    if [[ $? -ne 0 ]]; then
        echo "show diff between local branch and remote branch failed"
        return 1
    fi

    merge_info=$(get_new_merge_info)
    if [[ $? -ne 0 ]]; then
        echo "get merge information failed"
        return 1
    fi

    merge_title=$(get_merge_title "${merge_info}")
    if [[ $? -ne 0 ]]; then
        echo "get merge title failed"
        return 1
    fi

    merge_desc=$(get_merge_description "${merge_info}")
    if [[ $? -ne 0 ]]; then
        echo "get merge desc failed"
        return 1
    fi

    create_result=$(create_merge "${project_id}" "${local_branch}" "${remote_branch}" "${merge_title}" "${merge_desc}" "${assignee_id}")
    if [[ $? -ne 0 ]]; then
        echo "create merge request failed"
        return 1
    fi

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
    local branch_name
    local dialog_content=""
    declare -a branch_list

    local local_branchs=$(get_local_branchs "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get local branchs failed"
        return 1
    fi

    local i=0
    for branch in $local_branchs
    do
        i=$((i+1))

        branch_list[$i]="${branch}"
        dialog_content="${dialog_content} ${i} ${branch} off"
    done

    branch_name=$(dialog --stdout --radiolist "选择本地分支" 300 300 $i $dialog_content)
    if [[ $? -ne 0 ]]; then
        echo "get local branch failed"
        return 1
    fi

    echo "${branch_name}"
    return 0
}

get_remote_branch()
{
    local branch_name
    local dialog_content=""
    declare -a branch_list

    local remote_branchs=$(get_remote_branchs "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get remote branchs failed"
        return 1
    fi

    local i=0
    for branch in $remote_branchs
    do
        i=$((i+1))

        branch_list[$i]="${branch}"
        dialog_content="${dialog_content} ${i} ${branch} off"
    done

    branch_name=$(dialog --stdout --radiolist "选择远程合并分支" 300 300 $i $dialog_content)
    if [[ $? -ne 0 ]]; then
        echo "get remote branch failed"
        return 1
    fi

    echo "${branch_name}"
    return 0
}

get_merge_file_path()
{
    local merge_id=$1
    if [[ -z $merge_id ]]; then
        echo "merge id(${merge_id}) not found"
        return 1
    fi

    echo "${PANDA_TMP_DIR}/${merge_id}${MERGE_FILE_SUFFIX}"
    return 0
}

show_merge_diff()
{
    return 0
}

edit_file() {
    local file_path=$1

    vim "${file_path}"
    if [[ $? -ne 0 ]]; then
        echo "get file content failed"
        return 1
    fi

    cat "${file_path}"
    if [[ $? -ne 0 ]]; then
        echo "get file(${file_path}) content failed"
        return 1
    fi

    return 0
}

update_merge_template_file() {
    local file_path=$1
    local merge_content=$2

    [[ -e "${file_path}" ]] || cp "${MERGE_TEMPLATE_FILE}" "${file_path}"
    if [[ $? -ne 0 ]]; then
        echo "copy merge template file(${MERGE_TEMPLATE_FILE}) to(${file_path}) failed"
        return 1
    fi

    # 合并信息为空时，不需要更新
    if [[ -z $merge_content ]]; then
        return 0
    fi

    # 更新各种信息

    return 0
}

get_new_merge_info()
{
    local merge_content=$1
    local new_merge_content=

    local merge_id
    local merge_info_file

    merge_id=$(uuid)
    if [[ $? -ne 0 ]]; then
        echo "generate merge file id(${merge_id}) failed"
        return 1
    fi

    merge_info_file=$(get_merge_file_path "${merge_id}")
    if [[ $? -ne 0 ]]; then
        echo "get merge info file path failed"
        return 1
    fi

    update_merge_template_file "${merge_info_file}" "${merge_content}"
    if [[ $? -ne 0 ]]; then
        echo "update merge info(${merge_content}) to file(${merge_info_file}) failed"
        return 1
    fi

    new_merge_content=$(edit_file "${merge_info_file}")
    if [[ $? -ne 0 ]]; then
        echo "edit file(${merge_info_file}) failed"
        return 1
    fi

    echo "${new_merge_content}"
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
    initialize_env
    if [[ $? -ne 0 ]]; then
        echo "initialize env failed"
        return 1
    fi

    local user_cmd=$1
    case $user_cmd in 
        create_merge)
            create_merge_request
            ;;
        update_merge)
            update_merge_request
            ;;
        reopen_merge)
            reopen_merge_request
            ;;
        help|*)
            print_help
            ;;
    esac
}

main "$@"


