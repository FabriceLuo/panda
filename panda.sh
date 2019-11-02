#!/bin/bash

. merge.sh
. repo.sh
. branch.sh
. defect.sh

CUR_WORK_DIR=
PANDA_TMP_DIR="/tmp/panda"
MERGE_FILE_SUFFIX=".md"
MERGE_TEMPLATE_FILE=""
MERGE_REVIEW_PERSONS_CACHE_FILE=

# defect status: new, open, reopen, 重现中
DEFECT_STATUSES_NEED_HANDLE="10001,10002,10006,10005"

initialize_env()
{
    CUR_WORK_DIR=$PWD
}


set_content_between()
{
    local content=$1
    local begin_match=$2
    local end_match=$3
    local value=$4
    local new_content=

    new_content=$(echo "${content}" | sed "/${begin_match}/{:a;\$!{N;ba};s/${begin_match}.*${end_match}/${begin_match}\n${value}\n${end_match}/}")
    if [[ $? -ne 0 ]]; then
        echo "set content to value(${value}) failed"
        return 1
    fi 

    echo "${new_content}"
    return 0
}

get_content_between()
{
    local content=$1
    local begin_match=$2
    local end_match=$3
    local value=

    value=$(echo -e "${content}" | sed "/${begin_match}/,/${end_match}/! d;//d")
    if [[ $? -ne 0 ]]; then
        echo "get content value failed"
        return 1
    fi

    echo "${value}"
    return 0
}


set_merge_defect()
{
    local merge_info=$1
    local defect_id=$2
    local begin_match='<!-- defect begin -->'
    local end_match='<!--  defect end  -->'
    local new_merge_info=

    new_merge_info=$(set_content_between "${merge_info}" "${begin_match}" "${end_match}" "${defect_id}")
    if [[ $? -ne 0 ]]; then
        echo "set merge defect id failed"
        return 1
    fi

    echo "${new_merge_info}"
    return 0
}

get_merge_defect() {
    local merge_info=$1
    local begin_match='<!-- defect begin -->'
    local end_match='<!--  defect end  -->'
    local defect_id

    defect_id=$(get_content_between "${merge_info}" "${begin_match}" "${end_match}")
    if [[ $? -ne 0 ]]; then
        echo "get merge defect id failed"
        return 1
    fi

    echo "${defect_id}"
    return 0
}

set_merge_reviewers()
{
    local merge_info=$1
    local reviewer_ids=$2
    local begin_match='<!-- reviewers begin -->'
    local end_match='<!--  reviewers end  -->'
    local new_merge_info=

    if [[ -z $reviewer_ids ]]; then
        return 0
    fi

    reviewer_ids=$(echo "${reviewer_ids}" | sed 's/^/@/g')
    if [[ $? -ne 0 ]]; then
        echo "convert reviewer ids failed"
        return 1
    fi

    new_merge_info=$(set_content_between "${merge_info}" "${begin_match}" "${end_match}" "${reviewer_ids}")
    if [[ $? -ne 0 ]]; then
        echo "set merge reviewers id failed"
        return 1
    fi

    echo "${new_merge_info}"
    return 0
}

get_merge_title() {
    local merge_info=$1
    local begin_match='<!-- title begin -->'
    local end_match='<!--  title end  -->'
    local merge_title

    merge_title=$(get_content_between "${merge_info}" "${begin_match}" "${end_match}")
    if [[ $? -ne 0 ]]; then
        echo "get merge title failed"
        return 1
    fi

    echo "${merge_title}"
    return 0

    return 0
}

get_merge_description()
{
    local merge_info=$1
    local begin_match='<!-- description begin -->'
    local end_match='<!--  description end  -->'
    local merge_desc

    merge_desc=$(get_content_between "${merge_info}" "${begin_match}" "${end_match}")
    if [[ $? -ne 0 ]]; then
        echo "get merge desc failed"
        return 1
    fi

    #echo "${merge_desc}"
    python -c "import urllib; print urllib.quote('''${merge_desc}''')"
    #return 0
    return $?
}

get_current_project_id()
{
    local repo_url
    local repo_name

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
    echo "${project_id}"

    return 0
}

get_merge_template()
{
    cat "${MERGE_TEMPLATE_FILE}"

    return $?
}

update_review_persons_cache() {
    local cache_dir=

    cache_dir=$(dirname "${MERGE_REVIEW_PERSONS_CACHE_FILE}")
    if [[ ! -d "${cache_dir}" ]]; then
        mkdir -p "${cache_dir}"
        if [[ $? -ne 0 ]]; then
            echo "create review persons cache dir failed"
            return 1
        fi
    fi

    review_persons=$(list_review_persons)
    if [[ $? -ne 0 ]]; then
        echo "get review person list failed"
        return 1
    fi

    persons=$(echo "${review_persons}" | jq --raw-output 'map(.name + "@" + .username) | .[]' | sed 's/[0-9a-zA-Z]*@/@/g' | grep -v -E 'VT|All')
    if [[ $? -ne 0 ]]; then
        echo "get review person info failed"
        return 1
    fi

    echo "${persons}" > "${MERGE_REVIEW_PERSONS_CACHE_FILE}"
    return $?
}

get_review_persons_from_cache() {
    if [[ ! -f "${MERGE_REVIEW_PERSONS_CACHE_FILE}" ]]; then
        update_review_persons_cache
        if [[ $? -ne 0 ]]; then
            echo "update review persons cache failed"
            return 1
        fi
    fi

    cat "${MERGE_REVIEW_PERSONS_CACHE_FILE}"
    return $?
}

get_one_review_person()
{
    local prompt=$1
    local person_name=
    local persons=
    local person=
    local errcode

    # 排除VT及All组
    persons=$(get_review_persons_from_cache | grep -v -E 'VT|All')
    if [[ $? -ne 0 ]]; then
        echo "get review person from cache failed"
        return 1
    fi
    
    person=$(get_fzf_selection "${persons}" "${prompt}")
    errcode=$?
    if [[ $errcode -ne 0 ]]; then
        echo "get one review person failed"
        return $errcode
    fi

    person_name=$(echo "${person}" | cut -f 2 -d '@')
    if [[ $? -ne 0 ]]; then
        echo "get review person name failed"
        return 1
    fi
    echo "${person_name}"
    return 0
}

get_assignee_id()
{
    local assignee_id=

    assignee_id=$(get_one_review_person "选择合并人")
    if [[ $? -ne 0 ]]; then
        echo "get assignee person failed"
        return 1
    fi

    echo "${assignee_id}"
    return 0
}

get_reviewer_ids() {
    local reviewer_ids=
    local reviewer_id=
    local errcode=

    while :
    do
        reviewer_id=$(get_one_review_person "选择审核人")
        errcode=$?

        if [[ $errcode -eq 130 ]]; then
            break
        elif [[ $errcode -eq 0 ]]; then
            if [[ -z $reviewer_ids ]]; then
                reviewer_ids=$reviewer_id
            else
                reviewer_ids="${reviewer_ids}\n${reviewer_id}"
            fi
        else
            echo "get one review person failed"
            return 1
        fi
    done

    echo -e "${reviewer_ids}"
    return 0
}

create_merge_request()
{
    local src_branch
    local des_branch
    local merge_info
    local merge_title
    local merge_desc
    local project_id
    local create_result
    local create_failed
    local assignee_id
    local reviewer_ids

    project_id=$(get_current_project_id)
    if [[ $? -ne 0 ]]; then
        echo "get current repo project id failed"
        return 1
    fi

    src_branch=$(get_src_branch)
    if [[ $? -ne 0 ]]; then
        echo "get local branch failed"
        return 1
    fi

    des_branch=$(get_des_branch)
    if [[ $? -ne 0 ]]; then
        echo "get remote branch failed"
        return 1
    fi
    if [[ $src_branch == $des_branch ]]; then
        echo "merge src branch and des branch can not be same, branch:${src_branch}"
        return 1
    fi

    show_merge_diff  "${src_branch}" "${des_branch}"
    if [[ $? -ne 0 ]]; then
        echo "show diff between local branch and remote branch failed"
        return 1
    fi

    merge_info=$(get_merge_template)
    if [[ $? -ne 0 ]]; then
        echo "get merge template failed"
        return 1
    fi

    # 选择对应的缺陷ID
    defect_id=$(get_defect_to_fix)
    if [[ $? -ne 0 ]]; then
        echo "get defect to fix failed"
        return 1
    fi
    merge_info=$(set_merge_defect "${merge_info}" "${defect_id}")
    if [[ $? -ne 0 ]]; then
        echo "update merge defect failed"
        return 1
    fi

    reviewer_ids=$(get_reviewer_ids)
    if [[ $? -ne 0 ]]; then
        echo "get reviewer ids failed"
        return 1
    fi
    merge_info=$(set_merge_reviewers "${merge_info}" "${reviewer_ids}")
    if [[ $? -ne 0 ]]; then
        echo "update merge reviews failed"
        return 1
    fi

    assignee_id=$(get_assignee_id)
    if [[ $? -ne 0 ]]; then
        echo "get assignee person failed"
        return 0
    fi

    merge_info_file=$(generate_merge_info_file_path)
    if [[ $? -ne 0 ]]; then
        echo "generate merge info file failed"
        return 1
    fi
    update_merge_template_file "${merge_info_file}" "${merge_info}"
    if [[ $? -ne 0 ]]; then
        echo "update merge info(${merge_info}) to file(${merge_info_file}) failed"
        return 1
    fi
    edit_file "${merge_info_file}"
    if [[ $? -ne 0 ]]; then
        echo "edit file(${merge_info_file}) failed"
        return 1
    fi

    merge_info=$(cat "${merge_info_file}")

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

    create_result=$(create_merge "${project_id}" "${src_branch}" "${des_branch}" "${merge_title}" "${merge_desc}" "${assignee_id}")
    if [[ $? -ne 0 ]]; then
        echo "create merge request failed"
        return 1
    fi

    create_failed=$(echo "${create_result}" | jq 'has("error") or has("message")')
    if [[ $? -ne 0 ]]; then
        echo "get merge create result info failed"
        return 1
    fi

    if [[ $create_failed == "true" ]]; then
        echo "create merge request failed, error:${create_result}"
        return 1
    fi
    return 0
}

update_merge_request()
{
    local project_id
    local merge_info
    local new_merge_info=
    local merge_title
    local merge_desc

    project_id=$(get_current_project_id)
    if [[ $? -ne 0 ]]; then
        echo "get current repo project id failed"
        return 1
    fi

    merge_id=$(get_merge_to_update "${project_id}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge request to update failed"
        return 1
    fi

    merge_info=$(get_merge "${merge_id}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge(${merge_id}) info failed"
        return 1
    fi

    new_merge_info=$(get_new_merge_info "${merge_info}")
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

    update_result=$(create_merge "${project_id}" "${merge_id}" "${remote_branch}" "${merge_title}" "${merge_desc}" "${assignee_id}")
    if [[ $? -ne 0 ]]; then
        echo "update merge request failed"
        return 1
    fi

    return 0
}

close_merge_request()
{
    local project_id
    local merge_id
    local close_result

    project_id=$(get_current_project_id)
    if [[ $? -ne 0 ]]; then
        echo "get current repo project id failed"
        return 1
    fi

    merge_id=$(get_merge_to_close "${project_id}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge request to close failed"
        return 1
    fi

    close_result=$(close_merge "${project_id}" "${merge_id}")
    if [[ $? -ne 0 ]]; then
        echo "close merge request failed"
        return 1
    fi

    return 0
}

reopen_merge_request()
{
    local project_id
    local merge_id
    local close_result

    project_id=$(get_current_project_id)
    if [[ $? -ne 0 ]]; then
        echo "get current repo project id failed"
        return 1
    fi

    merge_id=$(get_merge_to_reopen "${project_id}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge request to reopen failed"
        return 1
    fi

    close_result=$(reopen_merge "${project_id}" "${merge_id}")
    if [[ $? -ne 0 ]]; then
        echo "reopen merge request failed"
        return 1
    fi

    return 0
}

get_fzf_selection() {
    local selections=$1
    local prompt=$2
    local print_query=$3
    local selection=

    if [[ -n $print_query ]]; then
        print_query="--print_query"
    fi

    selection=$(echo "${selections}" | fzf $print_query --prompt "${prompt} ->:")
    local errcode=$?
    if [[ $errcode -eq 130 ]]; then
        echo "select was canlled"
        return $errcode
    fi

    if [[ $errcode -ne 0 ]]; then
        echo "get select failed"
        return $errcode
    fi

    echo "${selection}"
    return 0
}

get_branch_from_branchs() {
    local branchs=$1
    local prompt=$2 

    local branch

    branch=$(get_fzf_selection "${branchs}" "${prompt}")
    if [[ $? -ne 0 ]]; then
        echo "select branch failed"
        return 1
    fi
    echo "${branch}"
    return 0
}

get_src_branch()
{
    local branch_name
    local src_branchs

    src_branchs=$(get_remote_branchs "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get local branchs failed"
        return 1
    fi

    branch_name=$(get_branch_from_branchs "${src_branchs}" "选择源分支")
    if [[ $? -ne 0 ]]; then
        echo "get local branch failed"
        return 1
    fi

    echo "${branch_name}"
    return 0
}

get_des_branch()
{
    local branch_name
    local remote_branchs

    remote_branchs=$(get_remote_branchs "${CUR_WORK_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "get remote branchs failed"
        return 1
    fi

    branch_name=$(get_branch_from_branchs "${remote_branchs}" "选择目的分支")
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

    return 0
}

update_merge_template_file()
{
    local file_path=$1
    local merge_content=$2
    local file_dir

    file_dir=$(dirname "${file_path}")
    if [[ $? -ne 0 ]]; then
        echo "get file(${file_path}) dir failed"
        return 1
    fi

    [[ -e "${file_dir}" ]] || mkdir -p "${file_dir}"
    if [[ $? -ne 0 ]]; then
        echo "mkdir dir(${file_dir}) failed"
        return 1
    fi

    # 合并信息为空时，不需要更新
    if [[ -z $merge_content ]]; then
        cp -f "${MERGE_TEMPLATE_FILE}" "${file_path}"
    else
        echo "${merge_content}" > "${file_path}"
    fi

    if [[ $? -ne 0 ]]; then
        echo "generate merge info file failed"
        return 1
    fi

    return 0
}

generate_merge_info_file_path()
{
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

    echo "${merge_info_file}"
    return 0
}

get_project_one_merge()
{
    local project_id=$1
    local merge_status=$2
    local merge_id=

    project_merges=$(list_merges "${project_id}" "${merge_status}")
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge(${merge_status}) list failed"
        return 1
    fi

    merge_id=$(get_merge_from_merges "${project_merges}")
    if [[ $? -ne 0 ]]; then
        echo "get merge from list failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_merge_info()
{
    local project_id=$1
    local merge_id=$2

    return 0
}

get_merge_from_merges()
{
    local project_merges=$1
    local merge
    local merge_id

    merge=$(get_fzf_selection "${project_merges}")
    if [[ $? -ne 0 ]]; then
        echo "get merge selection failed"
        return 1
    fi

    merge_id=$(echo "${merge}" | awk '{print $1}')
    if [[ $? -ne 0 ]]; then
        echo "get merge id failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_merge_to_update()
{
    local project_id=$1
    local merge_status="opened"
    local merge_id=

    merge_id=$(get_project_one_merge "${project_id}" "${merge_status}")
    if [[ $? -ne 0 ]]; then
        echo "get merge from list failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_merge_to_close()
{
    local project_id=$1
    local merge_status="opened"
    local merge_id=

    merge_id=$(get_project_one_merge "${project_id}" "${merge_status}")
    if [[ $? -ne 0 ]]; then
        echo "get merge from list failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_merge_to_reopen()
{
    local project_id=$1
    local merge_status="closed"
    local merge_id=

    merge_id=$(get_project_one_merge "${project_id}" "${merge_status}")
    if [[ $? -ne 0 ]]; then
        echo "get merge from list failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_merge_to_fix()
{
    local project_id=$1
    local merge_status="all"
    local merge_id=

    merge_id=$(get_project_one_merge "${project_id}" "${merge_status}")
    if [[ $? -ne 0 ]]; then
        echo "get merge from list failed"
        return 1
    fi

    echo "${merge_id}"
    return 0
}

get_defect_from_defects() {
    local defects=$1
    local defect
    local defect_id=

    defect=$(echo "${defects}" | jq --raw-output 'map(.key + " " +  .fields.summary) | .[]' | fzf --print-query)
    local errcode=$?
    if [[ $errcode -eq 130 ]]; then
        echo "defect select was canlled"
        return 1
    fi

    if [[ $errcode -ne 0 ]]; then
        echo "get defect select failed"
        return 1
    fi

    defect_id=$(echo "${defect}" | sed -n '2p' | awk '{print $1}')
    if [[ $? -ne 0 ]]; then
        echo "get defect id failed"
        return 1
    fi

    echo "${defect_id}"
    return 0
}

get_defect_to_fix() {
    local defects
    local defect_id

    defects=$(get_defects_by_me "${DEFECT_STATUSES_NEED_HANDLE}")
    if [[ $? -ne 0 ]]; then
        echo "get defect list to fix failed"
        return 1
    fi

    defect_id=$(get_defect_from_defects "${defects}")
    if [[ $? -ne 0 ]]; then
        echo "get defect id to fix failed"
        return 1
    fi

    echo "${defect_id}"
    return 0
}

generate_defect_fix_info()
{
    return 0
}

fix_defect_request()
{
    local project_id
    local defect_id
    local merge
    local merge_id
    local merge_desc

    project_id=$(get_current_project_id)
    if [[ $? -ne 0 ]]; then
        echo "get current repo project id failed"
        return 1
    fi

    merge_id=$(get_merge_to_fix "${project_id}")
    if [[ $? -ne 0 ]]; then
        echo "get merge to fix failed"
        return 1
    fi

    if [[ -n $merge_id ]]; then
        merge=$(get_merge "${project_id}" "${merge_id}")
        if [[ $? -ne 0 ]]; then
            echo "get merge(${merge_id}) info failed"
            return 1
        fi
    fi

    # merge不为空时，从merge中获取defect id
    if [[ -n $merge ]]; then
        merge_desc=$(echo "${merge}" | jq '.description')
        if [[ $? -ne 0 ]]; then
            echo "get merge desc failed"
            return 1
        fi

        defect_id=$(get_merge_defect "${merge_desc}")
        if [[ $? -ne 0 ]]; then
            echo "get defect id from merge failed"
            return 1
        fi
    fi

    if [[ -z $defect_id ]]; then
        defect_id=$(get_defect_to_fix)
        if [[ $? -ne 0 ]]; then
            echo "get defect to fix failed"
            return 1
        fi
    fi

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
        close_merge)
            close_merge_request
            ;;
        fix_defect)
            fix_defect_request
            ;;
        help|*)
            print_help
            ;;
    esac
}

main "$@"
