// JSON to string
function encodeJSON(data) {
    return encodeURIComponent(JSON.stringify(data)).replace(/"/g, '%22').replace(/'/g, '%27');
}

// string to JSON
function decodeJSON(str) {
    try {
        return JSON.parse(decodeURIComponent(str));
    } catch (e) {
        return [];
    }
}

// 알림 (toast)
function toast(type, heading, text) {
    var bg, icon;
    switch (type) {
        case 'success':
            bg = '#5ba035';
            icon = 'success';
            break;
        case 'info':
            bg = '#3b98b5';
            icon = 'info';
            break;
        case 'warning':
            bg = '#f7b84b';
            icon = 'warning';
            break;
        case 'danger':
            bg = '#bf441d';
            icon = 'error';
            break;
    }
    $.toast({
        heading: heading,
        text: text,
        position: 'top-right',
        loaderBg: bg,
        icon: icon,
        hideAfter: 5000,
        stack: 3,
    });
}

// swal alert
function swal(option, callback) {
    if (!option.type || !option.text) {
        throw 'swal parameter error';
    }
    // 이벤트 충돌로 flatpickr 비활성화
    $('.flatpickr-input:not(:disabled)').attr('disabled', true).addClass('tmpDisabled');

    Swal.fire({
        text: option.text,
        icon: option.type,
        buttonsStyling: false,
        confirmButtonText: 'Confirm',
        customClass: {
            confirmButton: 'btn btn-primary',
        },
    }).then(result => {
        $('.flatpickr-input.tmpDisabled').removeAttr('disabled').removeClass('tmpDisabled');

        if (result.value) {
            if (callback) callback();
            if (option.callback) option.callback();
        }
    });
}
function swalConfirm(option, callback, falseCallback) {
    if (!option.type || !option.text || !option.callback) {
        throw 'swal parameter error';
    }
    // 이벤트 충돌로 flatpickr 비활성화
    $('.flatpickr-input:not(:disabled)').attr('disabled', true).addClass('tmpDisabled');

    Swal.fire({
        text: option.text,
        icon: option.type,
        showCancelButton: true,
        confirmButtonText: 'Confirm',
        cancelButtonText: 'Cancel',
        customClass: {
            confirmButton: 'btn btn-primary',
            cancelButton: 'btn btn-outline-danger ml-1',
        },
        buttonsStyling: false,
    }).then(function (result) {
        $('.flatpickr-input.tmpDisabled').removeAttr('disabled').removeClass('tmpDisabled');

        if (result.value) {
            if (callback) callback();
            if (option.callback) option.callback();
        } else {
            if (falseCallback) falseCallback();
            if (option.falseCallback) option.falseCallback();
        }
    });
}
function swalConfirmNoCancel(option, callback, falseCallback) {
    if (!option.type || !option.text || !option.callback) {
        throw 'swal parameter error';
    }
    // 이벤트 충돌로 flatpickr 비활성화
    $('.flatpickr-input:not(:disabled)').attr('disabled', true).addClass('tmpDisabled');

    Swal.fire({
        text: option.text,
        icon: option.type,
        showCancelButton: false,
        confirmButtonText: 'Confirm',
        //cancelButtonText: '취소',
        customClass: {
            confirmButton: 'btn btn-primary',
            //cancelButton: 'btn btn-outline-danger ml-1',
        },
        buttonsStyling: false,
    }).then(function (result) {
        $('.flatpickr-input.tmpDisabled').removeAttr('disabled').removeClass('tmpDisabled');

        if (result.value) {
            if (callback) callback();
            if (option.callback) option.callback();
        } else {
            if (falseCallback) falseCallback();
            if (option.falseCallback) option.falseCallback();
        }
    });
}
//바이트 길이로 제한
function limitWordLengthByByte(targetElement, limitByte, errorMessage) {
    if (Number(byteCheck(targetElement)) > Number(limitByte)) {
        swal({
            text: errorMessage || `입력 가능한 글자 수를 초과했습니다.\n${limitByte}Byes(한글 기준 ${limitByte / 2}자) 까지 입력 가능합니다.`,
            icon: 'error',
        });
        for (i = 0; i < targetElement.value.length; i++) {
            thisObject.val(targetElement.value.substring(0, targetElement.value.length - 1));
            if (Number(byteCheck(targetElement)) <= Number(limitByte)) {
                break;
            }
        }
    }
    return;
}
// string 바이트 계산
function byteCheck(el) {
    var codeByte = 0;
    for (var idx = 0; idx < el.val().length; idx++) {
        var oneChar = escape(el.val().charAt(idx));
        if (oneChar.length == 1) {
            codeByte++;
        } else if (oneChar.indexOf('%u') != -1) {
            codeByte += 2;
        } else if (oneChar.indexOf('%') != -1) {
            codeByte++;
        }
    }
    return codeByte;
}

// 콤마 삽입
function numberFormat(num, fixed = 2, pad = false) {
    if (num === '' || num === null || num === undefined) return '0';
    num = +num;
    if (typeof num !== 'number' || num === 0) return '0';
    const regexp = /\B(?=(\d{3})+(?!\d))/g;
    // 기본 fixed : 2 (소수 셋째자리에서 반올림 처리. 둘째자리 까지 표현)
    if (fixed) {
        const unit = 10 ** fixed;
        num = Math.round(num * unit) / unit;
        let [part1, part2] = num.toString().split('.');
        if (pad) {
            part2 = (part2 || '').padEnd(fixed, 0);
        }
        return `${part1.replace(regexp, ',')}${part2 ? `.${part2}` : ''}`;
    }
    return Math.round(num).toString().replace(regexp, ',');
}

//null,undefined,'' 체크
function isNullorEmpty(val) {
    if (val != '' && val != null && val != undefined) {
        return false;
    } else {
        return true;
    }
}

// 콤마 삽입 된 문자를 정수 변환
function numberStrToNum(f_param) {
    if (!f_param) return 0;
    return parseFloat(f_param.toString().replace(/[^-.0-9]/g, ''));
}

// 쿠키 생성
var setCookie = function (name, value, day) {
    var date = new Date();
    date.setTime(date.getTime() + day * 60 * 60 * 24 * 1000);
    document.cookie = name + '=' + value + ';expires=' + date.toUTCString() + ';path=/';
};

// 쿠키 조회
var getCookie = function (name) {
    var value = document.cookie.match('(^|;) ?' + name + '=([^;]*)(;|$)');
    return value ? value[2] : null;
};

// 쿠키 삭제
var deleteCookie = function (name) {
    var date = new Date();
    document.cookie = name + '= ' + '; expires=' + date.toUTCString() + '; path=/';
};

//그룹화
function groupBy(objectArray, property) {
    return objectArray.reduce((acc, obj) => {
        const key = obj[property];
        if (!acc[key]) {
            acc[key] = [];
        }
        acc[key].push(obj);
        return acc;
    }, {});
}

//ID 만들기
function guid() {
    function s4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
}
function guid_wk() {
    const timestamp = new Date().getTime().toString(16);
    function s4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }

    return timestamp + '-' + s4() + '-' + s4() + s4();
}

//
function getUrlQuery() {
    url = location.search;
    var qIndex = url.indexOf('?');
    if (qIndex === -1) return {};
    var qs = url.substring(qIndex + 1).split('&');
    for (var i = 0, result = {}; i < qs.length; i++) {
        qs[i] = qs[i].split('=');
        result[qs[i][0]] = decodeURIComponent(qs[i][1]);
    }
    return result;
}

function urlQueryToString(url_query) {
    let str = '?';
    let i = 0;
    for (let query in url_query) {
        if (url_query[query] != null && !isNullorEmpty(query)) {
            if (i !== 0) str += '&';
            str += query + '=' + url_query[query];
        }
        i++;
    }
    return str;
}

//
function getUrlParam(name) {
    var url_string = window.location.href;
    var url = new URL(url_string);
    var c = url.searchParams.get(name);
    return c;
}

function addSpinToBtn(param) {
    const element = typeof param === 'string' ? document.getElementById(param) : param;
    element.setAttribute('data-kt-indicator', 'on');
    element.disabled = true;
}
function removeSpinToBtn(param) {
    const element = typeof param === 'string' ? document.getElementById(param) : param;
    element.removeAttribute('data-kt-indicator');
    element.disabled = false;
}

function handleAjaxError(jqXHR) {
    console.log(jqXHR.status);
    console.log(jqXHR.statusText);
    console.log(jqXHR.responseJSON);
    if (typeof jqXHR.responseJSON === 'string') {
        alert(jqXHR.responseJSON);
        return;
    } else if (typeof jqXHR.responseJSON === 'object') {
        var values = Object.values(jqXHR.responseJSON);
        var errMsg = '';
        for (value of values) {
            if (value instanceof Array) errMsg += value.join(', ');
            else if (typeof value === 'string') errMsg += value;
            errMsg += '\n';
        }
        alert(errMsg);
    }
}

function nextFocus(el, event) {
    if (event.keyCode === 13) {
        const $el = $(el);
        const name = $el.attr('name');
        const $targets = $(`input[name=${name}]`);
        let found_flag = false;
        $targets.each(function (i, e) {
            if (found_flag) {
                e.focus();
                e.select();
                return false;
            } else if (e === el) {
                found_flag = true;
                // 마지막이면 처음로 가자
                if ($targets.length - 1 === i) {
                    $targets[0].focus();
                    $targets[0].select();
                }
            }
        });
    }
}
//오늘 날짜
function getToday() {
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth() + 1; //January is 0!
    var yyyy = today.getFullYear();
    if (dd < 10) {
        dd = '0' + dd;
    }
    if (mm < 10) {
        mm = '0' + mm;
    }
    return yyyy + '-' + mm + '-' + dd;
}
//날짜 더하기 빼기
function addDays(date, days) {
    const clone = new Date(date);
    const s_date = new Date(date);
    clone.setDate(s_date.getDate() + days);
    return yyyymmdd(clone);
}

// 두개의 날짜를 비교하여 차이를 알려준다.
function dateDiff(_date1, _date2) {
    var diffDate_1 = _date1 instanceof Date ? _date1 : new Date(_date1);
    var diffDate_2 = _date2 instanceof Date ? _date2 : new Date(_date2);

    diffDate_1 = new Date(diffDate_1.getFullYear(), diffDate_1.getMonth() + 1, diffDate_1.getDate());
    diffDate_2 = new Date(diffDate_2.getFullYear(), diffDate_2.getMonth() + 1, diffDate_2.getDate());

    var diff = (diffDate_2.getTime() - diffDate_1.getTime()) * -1;
    diff = Math.ceil(diff / (1000 * 3600 * 24));

    return diff * 1;
}

function thisweekDate() {
    var currentDay = new Date();
    var theYear = currentDay.getFullYear();
    var theMonth = currentDay.getMonth();
    var theDate = currentDay.getDate();
    var theDayOfWeek = currentDay.getDay();

    var thisWeek = [];

    for (var i = 0; i < 7; i++) {
        var resultDay = new Date(theYear, theMonth, theDate + (i - theDayOfWeek));
        var yyyy = resultDay.getFullYear();
        var mm = Number(resultDay.getMonth()) + 1;
        var dd = resultDay.getDate();

        mm = String(mm).length === 1 ? '0' + mm : mm;
        dd = String(dd).length === 1 ? '0' + dd : dd;

        thisWeek[i] = yyyy + '-' + mm + '-' + dd;
    }
    return thisWeek;
}
function thismonthDate(month, year) {
    var date = new Date(year, month, 1);
    var days = [];
    while (date.getMonth() === month) {
        days.push(yyyymmdd(date));
        date.setDate(date.getDate() + 1);
    }
    return days;
}

// Datatable
function getDTOption(option) {
    function initCompleteFirst(settings) {
        $(settings.nTableWrapper).wrap('<div class="scrolledTable"></div>');
    }
    return {
        scrollX: true,
        pageLength: 15,
        dom: '<"d-flex align-items-center justify-content-between flex-column flex-md-row"f<"html5buttons"B>>rit<"d-flex align-items-center justify-content-between"lp>',
        buttons: [
            {
                extend: 'copyHtml5',
                className: 'btn btn-sm',
                text: 'Copy',
                exportOptions: getCopyExportOptions(),
            },
            {
                extend: 'excelHtml5',
                className: 'btn btn-sm',
                customizeData: excelCustomizeData,
                title: option.excelTitle || null,
            },
            {
                extend: 'print',
                className: 'btn btn-sm',
                text: 'Print',
            },
        ],
        //ordering: !isNullorEmpty(option.order) ? "true" :"false",
        order: !isNullorEmpty(option.order) ? option.order : [],
        orderMulti: true,
        lengthMenu: [15, 50, 100, 200],
        info: false,
        language: {
            emptyTable: 'There is no data.',
            lengthMenu: '_MENU_ Rows',
            infoEmpty: 'Ther is no data',
            zeroRecords: 'There is no data or getting the data.',
            search: 'Search ',
        },
        ...option,
        initComplete: function (settings, json) {
            initCompleteFirst(settings, json);
            if (option.initComplete) option.initComplete(settings, json);
        },
    };
}

// export에서 제외할 행 이름
const exportExcludes = ['선택', '+', '#'];

// export 복사 data 제외열 설정
function getCopyExportOptions() {
    return {
        columns: exportExcludes.map(name => `:visible:not(:contains(${name}))`).join(''),
    };
}

// export excel data 제외열 설정
function excelCustomizeData(data) {
    const regPercent = /^\d+(?:\.\d+)?%$/;

    // body 체크
    for (let i = 0; i < data.body.length; i++) {
        const newRow = [];
        for (let j = 0; j < data.body[i].length; j++) {
            // 제외열 체크
            if (!exportExcludes.includes(data.header[j])) {
                newRow.push(data.body[i][j]);
            }
        }
        data.body[i] = newRow;
    }
    // header 체크
    const newHeader = [];
    for (let i = 0; i < data.header.length; i++) {
        const header = data.header[i];
        if (!exportExcludes.includes(header)) newHeader.push(header);
    }
    data.header = newHeader;
    return data;
}

/**
 * input element에 정수 숫자만 입력받는 이벤트 지정하는 함수
 * @param {array} pa1 jquery element
 * @param {function | null} callBackFunc  이벤트 선언 이후 callback function
 * @param {{
 *      length: number|null,
 *      message: string|null,
 *      max: number|null,
 *      callback: function|null
 * } | null
 * } validationOption length: 제한길이, message: 제한길이 초과시 메세지, max: 최대값, callback: input 이후 callback function
 * @returns null
 */
function addEvent_numberComma(pa1, callBackFunc, validationOption) {
    if (typeof pa1 !== undefined) {
        for (var i = 0; i < pa1.length; i++) {
            var addEventFn = function () {
                var prevValue = null;
                return function () {
                    pa1[i].on('input', function (event) {
                        // 1.

                        // 2. 방향키 입력 제한
                        if ($.inArray(event.keyCode, [38, 40, 37, 39]) !== -1) {
                            event.preventDefault();
                            return;
                        }
                        // 3
                        var $this = $(this);
                        var inputStr = $this.val();

                        // 4. 숫자 외 문자 제거
                        var input = inputStr.replace(/[\D\s\._\-]+/g, '');

                        // 5. 제한 길이 검증
                        var MAX_LENGTH = validationOption && validationOption.length ? validationOption.length : Number.MAX_SAFE_INTEGER.toString().length - 2;
                        input = input ? parseInt(input, 10) : '';

                        // 6. 최대값 검증
                        var MAX_VALUE = validationOption && validationOption.max ? validationOption.max : null;
                        var errorMessage;

                        // 검증 실패 시 이전값 되돌리기
                        if (input.toString().length > MAX_LENGTH) {
                            event.preventDefault();
                            $this.val(numberFormat(prevValue));
                            errorMessage = validationOption && validationOption.message ? validationOption.message : MAX_LENGTH + '자리를 초과하여 입력할 수 없습니다.';
                            if (validationOption && validationOption.callback && jQuery.isFunction(validationOption.callback)) validationOption.callback(prevValue, $this);
                        }
                        if (MAX_VALUE && MAX_VALUE < +input) {
                            event.preventDefault();
                            errorMessage = numberFormat(MAX_VALUE) + '보다 큰 수를 입력할 수 없습니다.';
                            $this.val(numberFormat(MAX_VALUE));
                            if (validationOption && validationOption.callback && jQuery.isFunction(validationOption.callback)) validationOption.callback(MAX_VALUE, $this);
                        }
                        if (errorMessage) {
                            if (swal) {
                                swal({
                                    text: errorMessage,
                                    type: 'info',
                                });
                            } else {
                                alert(errorMessage);
                            }
                            return;
                        }

                        // 6. 반영
                        $this.val(function () {
                            // 0입력 가능하게
                            if (input == '0') {
                                if (validationOption && validationOption.callback && jQuery.isFunction(validationOption.callback)) validationOption.callback(0, $this);
                                return '0';
                            } else if (input == '') {
                                if (validationOption && validationOption.callback && jQuery.isFunction(validationOption.callback)) validationOption.callback(0, $this);
                                return '';
                            }
                            if (validationOption && validationOption.callback && jQuery.isFunction(validationOption.callback)) validationOption.callback(input, $this);
                            return numberFormat(input);
                        });
                    });
                    pa1[i].on('keydown', function (event) {
                        var $this = $(this);
                        prevValue = $this.val();
                    });
                };
            };
            var fn = addEventFn();
            fn();
        }
    }
    if (jQuery.isFunction(callBackFunc)) {
        callBackFunc();
    }
}
// 첫글자 대문자
function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function getDTDownloadFileHtml(fileInfoString) {
    let html = ``;
    if (!isNullorEmpty(fileInfoString)) {
        let boxHtml = fileInfoString
            .split('||')
            .map(i => {
                const splitStr = i.split('::');
                return `<div>
                            <a href='${splitStr[1]}' target='_blank' download='${splitStr[0]}'>
                                ${splitStr[0]}
                            </a>
                        </div>`;
            })
            .join();
        const id = Math.random().toString().substr(2, 14);
        html = `<a data-bs-html="true" id="${id}" data-bs-toggle="popover" role="button" data-bs-dismiss="true" data-bs-placement="bottom" data-bs-content="${boxHtml}" title="첨부파일<span role='button' class='popover-dismiss btn btn-icon id-${id}'></span>">
                    <i class="fa fa-solid fa-link"></i>
                </a>`;
    }
    $(document).off('click', '.popover-dismiss', closeFilePopover);
    $(document).on('click', '.popover-dismiss', closeFilePopover);
    return html;
}
function closeFilePopover(event) {
    const $el = $(event.target);
    let id = $el
        .attr('class')
        .split(' ')
        .filter(c => c.indexOf('id-') === 0);
    if (!id.length) return;
    id = id[0];
    id = id.substr(3, id.length);
    const targetEl = document.getElementById(id);
    if (!targetEl) return;
    const popover = bootstrap.Popover.getInstance(targetEl);
    popover.hide();
}

function addEventFocus_numberComma($els) {
    for (let $el of $els) {
        $el.on('focus', function () {
            $el.val($el.val().replace(/[^\d\.]/g, ''));
            $el.select();
        });
        $el.on('blur', function () {
            $el.val(numberFormat($el.val()));
        });
        $el.on('input', function () {
            $el.val($el.val().replace(/[^\d\.]/g, ''));
        });
    }
}

function s2ab(s) {
    var buf = new ArrayBuffer(s.length); //convert s to arrayBuffer
    var view = new Uint8Array(buf); //create uint8array as viewer
    for (var i = 0; i < s.length; i++) view[i] = s.charCodeAt(i) & 0xff; //convert to octet
    return buf;
}

function downloadExcel(title, dataJsonArray, option = {}) {
    var columnTitleArray = Object.keys(dataJsonArray[0]);

    var wb = XLSX.utils.book_new();
    var arrJSON = JSON.parse(JSON.stringify(dataJsonArray));
    var dataJsonKeyLength = dataJsonArray.length > 0 && Object.keys(dataJsonArray[0]).length;

    var ws = XLSX.utils.json_to_sheet(arrJSON, { header: columnTitleArray });
    ws = { ...ws, ...option };

    wb.Props = {
        Title: title,
        Subject: 'Excel',
        Author: 'Master',
        CreatedDate: new Date(),
    };

    wb.SheetNames.push(title);

    wb.Sheets[title] = ws;

    saveAs(
        new Blob(
            [
                s2ab(
                    XLSX.write(wb, {
                        bookType: 'xlsx',
                        type: 'binary',
                    }),
                ),
            ],
            {
                type: 'application/octet-stream',
            },
        ),
        title + '.xlsx',
    );
}

function yymmdd(date, delimiter = '-') {
    if (typeof date === 'string') date = new Date(date);
    if (!date) return ''; //date = new Date();
    const yyyy = date.getFullYear().toString().substr(2, 2);
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');

    return `${yyyy}${delimiter}${mm}${delimiter}${dd}`;
}

function yyyymmdd(date, delimiter = '-') {
    if (typeof date === 'string') date = new Date(date);
    if (!date) return ''; //date = new Date();
    const yyyy = date.getFullYear().toString();
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');

    return `${yyyy}${delimiter}${mm}${delimiter}${dd}`;
}

function yyyymmddHHMMSS(date, delimiter = '-') {
    if (typeof date === 'string') date = new Date(date);
    if (!date) date = new Date();
    const yyyy = date.getFullYear().toString();
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');
    const HH = date.getHours().toString().padStart(2, '0');
    const MM = date.getMinutes().toString().padStart(2, '0');
    const SS = date.getSeconds().toString().padStart(2, '0');

    return `${yyyy}${delimiter}${mm}${delimiter}${dd} ${HH}:${MM}:${SS}`;
}

function scheduleDetail(data, type, row) {
    if (!data) return '';
    const item = data.split('|');
    let noti = dateDiff(item[1], getToday()) <= 0 && item[2] === '' ? 'text-danger' : '';
    let team =
        item[4] &&
        item[4].split('^^').map(x => {
            return `<span class="badge badge-lg badge-light ms-1 fs-10 align-middle">${x.split(':')[1]}</span>`;
        });
    //return `<div class="d-flex" style="flex-direction: column;align-items: flex-start;"><span class="${noti}">${yymmdd(item[0],'/')} ~ ${yymmdd(item[1],'/')}</span><div >${team}</div></div>`;
    return `<div class="d-flex" style="flex-direction: column;align-items: flex-start;"><span class="${noti}">${yymmdd(item[0], '/')} ~ ${yymmdd(item[1], '/')}</span></div>`;
}

function dragElement(elmnt) {
    var pos1 = 0,
        pos2 = 0,
        pos3 = 0,
        pos4 = 0;
    if (elmnt.querySelector('.modal-content')) {
        // if present, the header is where you move the DIV from:
        elmnt.querySelector('.modal-content').onmousedown = dragMouseDown;
    } else {
        // otherwise, move the DIV from anywhere inside the DIV:
        elmnt.onmousedown = dragMouseDown;
    }

    function dragMouseDown(e) {
        e = e || window.event;
        e.preventDefault();
        // get the mouse cursor position at startup:
        pos3 = e.clientX;
        pos4 = e.clientY;
        document.onmouseup = closeDragElement;
        // call a function whenever the cursor moves:
        document.onmousemove = elementDrag;
    }

    function elementDrag(e) {
        e = e || window.event;
        e.preventDefault();
        // calculate the new cursor position:
        pos1 = pos3 - e.clientX;
        pos2 = pos4 - e.clientY;
        pos3 = e.clientX;
        pos4 = e.clientY;
        // set the element's new position:
        elmnt.style.top = elmnt.offsetTop - pos2 + 'px';
        elmnt.style.left = elmnt.offsetLeft - pos1 + 'px';
    }

    function closeDragElement() {
        // stop moving when mouse button is released:
        document.onmouseup = null;
        document.onmousemove = null;
    }
}

function debounce(func, timeout) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => {
            func.apply(this, args);
        }, timeout);
    };
}

function convertImageToBase64(url, callback) {
    const img = new Image();
    img.crossOrigin = 'Anonymous'; // CORS 이슈 방지
    img.onload = function () {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, img.width, img.height);
        const dataURL = canvas.toDataURL('image/png');
        callback(dataURL);
    };
    img.onerror = function () {
        console.error('Image upload failed: ', url);
        callback(null);
    };
    img.src = url;
}

function getInnerTextFromHTML(htmlString) {
    // DOMParser를 이용해 HTML 문자열을 Document 객체로 파싱
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlString, 'text/html');

    // HTML 문서의 body에서 innerText만 추출
    return doc.body.innerText || '';
}



