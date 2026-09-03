function button_display(process_status, user_type, completed, user_role) {
    
    var button_display = {
        save: 0,
        prerequest:0,
        request: 0,
        approval: 0,
        reject: 0,
        forward: 0,
        delete: 0,
        reuse: 0,
        input_comment: 0,
        published: 0,
        homepage : 0, //publish 된 품목을 홈페이지에 게시할 수 있는 버튼 reviewer 만 적용된다.
    };
    /*
    1). 사용자 (user)
      - 본인이 사용한 문서만 보여짐.
      - 본인이 결제한 문서만 보여짐.
      - pubished된 문서는 모두 볼수 있음.
      - 결제가 완료 된 문서는 삭제 할 수 없음.
      - 문서 작성 중일 때는 삭제할 수 있음.
    2) Reader
      - 문서를 만들수 있는 권한이 없음. --main page 에 new datasheet 버튼 숨김 처리
      - 모든 문서를 볼 수 있는 권한 만 있음.
      - 삭제 할 수 있는 권한이 없음.
    3) supporter
      - 문서를 만들 수 있는 권한이 있음.
      - 모든 문서를 볼수 있는 권한이 있음,
      - 삭제 할 수 있는 권한이 없음.
    4) 관리자 (admin)
      - 문서를 만들수 있음.
      - 어떤 곳이든 삭제 할 수 있는 권한이 있음.
      - 모든 문서를 볼 수 있음.
  */
    //문서에 요청자,결제자,publisher 가 등록 되지 않은 경우인데, role 이 READER 이면 버튼은 모두 안보이게 한다. 
    if ((user_role == 'READER' || user_role == 'SUPPORTER') && user_type=='') {
        return {
            save: 0,
            prerequest: 0,
            request: 0,
            approval: 0,
            reject: 0,
            forward: 0,
            delete: 0,
            reuse: 0,
            input_comment: 0,
            published: 0,
            homepage: 0
        }
    }


    //ok 이면 버튼이 안보여야 한다.
    if (completed == 'OK') {
        //결제중 -결제자
        if (process_status == 'Request' && user_type != 'D')
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 0,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 0,
                published: 0,
                copy: 0,
                homepage: 0
            };

        //결제완료 = 요청자
        if (process_status == 'Completed' && user_type == 'D')
            
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 1,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 1,
                published: user_type == 'R' ? 1 : 0, //publishe 는 admin role 만 가능하여 0으로 변경 2025-09-10
                //admin 은 publish 하지 못한다. wk2026-02-04 박기완님 카톡 및 통화
                copy: 1,
                homepage: 0,
                obsolete: user_type == 'R' || user_role == 'ADMIN'? 1 : 0 //publisher 만 obsolete 가능
            };
        //결제완료 = 결제자/reader
        if (process_status == 'Completed' && user_type != 'D')
            
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 1,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 1,
                published: user_type == 'R' ? 1 : 0, //admin role 을 가지고 있는 유저는 publish 가능하다.,또는 approval line 에 publisher 인경우
                //admin 은 publish 하지 못한다. wk2026-02-04 박기완님 카톡 및 통화
                copy: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 copy 가능하다                
                homepage: 0,
                obsolete: user_type == 'R' || user_role == 'ADMIN' ? 1 : 0 //publisher 만 obsolete 가능
            };
        //Obsoleted에 문서를 업로드한 경우,
        if (process_status == 'Obsoleted')
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 0,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 1,
                published: 0, //admin role 을 가지고 있는 유저는 publish 가능하다.,
                //copy: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 copy 가능하다                
                copy: 0, //homepage 는 published 리스트 안에 있어서 모든 유저가 copy 가능합니다. 
                homepage: 0,
                preview:0 //preview 도 막아야 해서, 여기만 preview 처리

            };
        //homepage에 문서를 업로드한 경우,
        if (process_status == 'Homepage' )
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 1,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 1,
                published: 0, //admin role 을 가지고 있는 유저는 publish 가능하다.,
                //copy: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 copy 가능하다                
                copy: 1, //homepage 는 published 리스트 안에 있어서 모든 유저가 copy 가능합니다. 
                homepage: 0,
                obsolete: user_type == 'R' || user_role == 'ADMIN' ? 1 : 0 //publisher 만 obsolete 가능
            };
        


        //publised  = 요청자-Published
        if (process_status == 'Published') { 
            //publishe 했을때 R(publisher) 유저는 homepage 에 올릴 수 있다. 
            if (user_type == 'R' || user_role == 'ADMIN') {                
                return {
                    save: 0,
                    prerequest: 0,
                    request: 0,
                    approval: 0,
                    reject: 0,
                    forward: 1,
                    delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가진 유저만 삭제 가능2025-09-10
                    reuse: 0,
                    input_comment: 1,
                    published: 0,
                    copy: 1,
                    homepage: 1,
                    obsolete: user_type == 'R' || user_role == 'ADMIN' ? 1 : 0 //publisher 만 obsolete 가능
                };
            }  
            //publish 되면 모든 유저가 copy 할 수 있습니다. 
            //if ((user_type == 'D' || user_role == 'ADMIN')) {
                return {
                    save: 0,
                    prerequest: 0,
                    request: 0,
                    approval: 0,
                    reject: 0,
                    forward: 0,
                    delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가진 유저만 삭제 가능2025-09-10
                    reuse: 0,
                    input_comment: 1,
                    published: 0,
                    copy: 1,
                    homepage: 0
                };
            //}        
                
        }
        //return {
        //    save: 0,
        //    request: 0,
        //    approval: 0,
        //    reject: 0,
        //    forward: 1,
        //    delete: 0,
        //    reuse: 1,
        //    input_comment: 1,
        //    published: 0,
        //    copy: 0
        //};
        //Reject = 요청자
        if (process_status == 'Reject' && user_type == 'D')
            
            return {
                save: 0,
                prerequest: 1,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 0,
                delete: 1,
                reuse: 1,
                input_comment: 0,
                published: 0,
                copy: 0,
                homepage: 0
            };

        //Reject = 결제자/reader
        if (process_status == 'Reject' && user_type != 'D')
            return {
                save: 0,
                prerequest: 0,
                request: 0,
                approval: 0,
                reject: 0,
                forward: 0,
                delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
                reuse: 0,
                input_comment: 0,
                published: 0,
                copy: 0,
                homepage: 0
            };
    }

    //요청자인데, save 인 상태

    if (process_status == 'SAVE' && user_type == 'D')
        return {
            save: 1,
            prerequest: 1,
            request: 1,
            approval: 0,
            reject: 0,
            forward: 0,
            delete: 1,
            reuse: 0,
            input_comment: 0,
            published: 0,
            copy: 0,
            homepage: 0
        };
    if (process_status == 'SAVE' && user_type != 'D')
        return {
            save: 0,
            prerequest: 0,
            request: 0,
            approval: 0,
            reject: 0,
            forward: 0,
            delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
            reuse: 0,
            input_comment: 0,
            published: 0,
            copy: 0,
            homepage: 0
        };
    //결제자
    if (process_status == 'Request' && (user_type == 'A' || user_type == 'P' || user_type == 'S'))
        return {
            save: 0,
            prerequest: 0,
            request: 0,
            approval: 1,
            reject: 1,
            forward: 0,
            delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
            reuse: 0,
            input_comment: 0,
            published: 0,
            copy: 0,
            homepage: 0
        };
    if (process_status == 'Request') // request 인데 a,p,s 가 아닌 경우
        return {
            save: 0,
            prerequest: 0,
            request: 0,
            approval: 0,
            reject: 0,
            forward: 0,
            delete: user_role == 'ADMIN' ? 1 : 0, //admin role 을 가지고 있는 유저는 삭제가 가능하다.
            reuse: 0,
            input_comment: 0,
            published: 0,
            copy: 0,
            homepage: 0
        };

    if (process_status == 'Completed' && user_type == 'V')
        return {
            save: 0,
            prerequest: 0,
            request: 0,
            approval: 0,
            reject: 0,
            forward: 1,
            delete: 0,
            reuse: 0,
            input_comment: 1,
            published: 0,
            copy: 0,
            homepage: 0
        };
    return button_display;
}
