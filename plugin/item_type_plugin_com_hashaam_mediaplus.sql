prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.0'
,p_default_workspace_id=>6375939148427884
,p_default_application_id=>1530
,p_default_id_offset=>0
,p_default_owner=>'WKSP_MRS'
);
end;
/
 
prompt APPLICATION 1530 - APEX Plugins By Hashaam
--
-- Application Export:
--   Application:     1530
--   Name:            APEX Plugins By Hashaam
--   Date and Time:   14:38 Sunday November 1, 2026
--   Exported By:     WKSP_MRS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 12115540231788950
--   Manifest End
--   Version:         26.1.0
--   Instance ID:     743364309778592
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/item_type/com_hashaam_mediaplus
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(12115540231788950)
,p_plugin_type=>'ITEM TYPE'
,p_name=>'COM.HASHAAM.MEDIAPLUS'
,p_display_name=>'MediaPlus'
,p_apexlang_name=>'mediaPlus'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_ITEMS'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/mediaPlus#MIN#.js?v=2.0.0-2626f35a'
,p_css_file_urls=>'#PLUGIN_FILES#css/mediaPlus#MIN#.css?v=2.0.0-2626f35a'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- MediaPlus for Oracle APEX - item plug-in PL/SQL (embedded in the plug-in, no database objects)',
'-- Recordings and photos are uploaded in parts while the page is open and kept in an APEX collection',
'-- (one member each) until a page process copies them into the application''s own table.',
'--   c001 file name, c002 MIME type, c003 AUDIO / VIDEO / IMAGE, c004 item name, n001 bytes, n002 seconds,',
'--   n003 / n004 photo width / height, d001 created, blob001 media, clob001 transcript',
'-- The item value is the colon-separated list of the collection seq_ids of its recordings and photos.',
'',
'c_parts   constant varchar2(10) := ''$PARTS'';',
'c_allow   constant number := 1.03;    -- MP4 sizes are estimated while recording: a recording may end slightly over the limit',
'c_uploads constant pls_integer := 3;  -- uploads in progress per item and session',
'c_spare   constant pls_integer := 5;  -- recordings per item kept beyond Maximum Recordings (reloads, other tabs)',
'',
'function attr ( p_item in apex_plugin.t_item, p_no in pls_integer ) return varchar2',
'is',
'begin',
'    return p_item.attributes.get_varchar2(''attribute_'' || to_char(p_no, ''FM00''));',
'exception',
'    when others then',
'        return null;',
'end attr;',
'',
'function num ( p_val in varchar2, p_default in number ) return number',
'is',
'begin',
'    return nvl(to_number(replace(trim(p_val), '','', ''.''), ''999999999990D999999'', ''NLS_NUMERIC_CHARACTERS=''''.,''''''), p_default);',
'exception',
'    when others then',
'        return p_default;',
'end num;',
'',
'function msg ( p_key in varchar2, p_default in varchar2, p0 in varchar2 default null ) return varchar2',
'is',
'    l_text varchar2(4000) := apex_lang.message(''MEDIAPLUS.'' || p_key, p0);',
'begin',
'    if l_text is null or l_text = ''MEDIAPLUS.'' || p_key then',
'        l_text := replace(p_default, ''%0'', p0);',
'    end if;',
'    return l_text;',
'end msg;',
'',
'function coll ( p_item in apex_plugin.t_item ) return varchar2',
'is',
'begin',
'    return upper(nvl(trim(attr(p_item, 16)), ''MEDIAPLUS''));',
'end coll;',
'',
'-- Mode: AUDIO, VIDEO, IMAGE in any combination (colon list); BOTH is the 1.x value for audio and video',
'function modes ( p_item in apex_plugin.t_item ) return varchar2',
'is',
'begin',
'    return replace(upper(nvl(attr(p_item, 1), ''AUDIO'')), ''BOTH'', ''AUDIO:VIDEO'');',
'end modes;',
'',
'function max_bytes ( p_item in apex_plugin.t_item ) return number',
'is',
'begin',
'    return round(num(attr(p_item, 2), 10) * 1048576);',
'end max_bytes;',
'',
'procedure ensure ( p_name in varchar2 )',
'is',
'begin',
'    if not apex_collection.collection_exists(p_name) then',
'        apex_collection.create_collection(p_name);',
'    end if;',
'end ensure;',
'',
'-- seq_ids in an item value (anything that is not a number is dropped)',
'function seqs ( p_value in varchar2 ) return apex_t_number',
'is',
'    l_list apex_t_varchar2 := apex_string.split(p_value, '':'');',
'    l_seqs apex_t_number := apex_t_number();',
'begin',
'    for i in 1 .. l_list.count loop',
'        if regexp_like(trim(l_list(i)), ''^\d{1,12}$'') then',
'            l_seqs.extend;',
'            l_seqs(l_seqs.count) := to_number(trim(l_list(i)));',
'        end if;',
'    end loop;',
'    return l_seqs;',
'end seqs;',
'',
'procedure json_header',
'is',
'begin',
'    sys.owa_util.mime_header(''application/json'', false);',
'    sys.htp.p(''Cache-Control: no-store'');',
'    sys.owa_util.http_header_close;',
'end json_header;',
'',
'procedure json_error ( p_message in varchar2 )',
'is',
'begin',
'    apex_json.open_object;',
'    apex_json.write(''error'', p_message);',
'    apex_json.close_object;',
'end json_error;',
'',
'procedure check_token ( p_token in varchar2 )',
'is',
'begin',
'    if p_token is null or not regexp_like(p_token, ''^[A-Za-z0-9]{8,64}$'') then',
'        raise_application_error(-20001, ''MediaPlus: invalid upload token'');',
'    end if;',
'end check_token;',
'',
'procedure send_blob ( p_blob in out nocopy blob, p_mime in varchar2, p_name in varchar2 )',
'is',
'begin',
'    sys.owa_util.mime_header(nvl(p_mime, ''application/octet-stream''), false);',
'    sys.htp.p(''Content-Length: '' || dbms_lob.getlength(p_blob));',
'    sys.htp.p(''Content-Disposition: inline; filename="'' || regexp_replace(p_name, ''[^A-Za-z0-9._ -]'', ''_'') || ''"'');',
'    sys.htp.p(''Cache-Control: private, max-age=600'');',
'    sys.owa_util.http_header_close;',
'    sys.wpg_docload.download_file(p_blob);',
'end send_blob;',
'',
'procedure not_found',
'is',
'begin',
'    sys.owa_util.status_line(404, ''Not Found'', true);',
'end not_found;',
'',
'-- the first bytes must be those of an audio / video container or a picture, whatever the browser claimed',
'function is_media ( p_blob in blob, p_kind in varchar2 ) return boolean',
'is',
'    l_head varchar2(40) := rawtohex(dbms_lob.substr(p_blob, 12, 1));',
'begin',
'    if p_kind = ''IMAGE'' then',
'        return l_head like ''FFD8FF%''                                -- JPEG',
'            or l_head like ''89504E470D0A1A0A%''                      -- PNG',
'            or (l_head like ''52494646%'' and substr(l_head, 17, 8) = ''57454250'')   -- WebP',
'            or l_head like ''47494638%''                              -- GIF',
'            or (substr(l_head, 9, 8) = ''66747970'' and substr(l_head, 17, 8) in (''68656963'', ''68656978'', ''6D696631'', ''61766966'')); -- HEIC / AVIF',
'    end if;',
'    return l_head like ''1A45DFA3%''                                  -- WebM / Matroska',
'        or substr(l_head, 9, 8) = ''66747970''                        -- MP4 / M4A / MOV / 3GP (ftyp)',
'        or l_head like ''4F676753%''                                  -- Ogg',
'        or (l_head like ''52494646%'' and substr(l_head, 17, 8) = ''57415645'')   -- WAV',
'        or l_head like ''494433%''                                    -- MP3 with ID3',
'        or regexp_like(substr(l_head, 1, 3), ''^FF[EF]'')             -- MP3 / AAC frames',
'        or l_head like ''664C6143%''                                  -- FLAC',
'        or l_head like ''2321414D52%'';                               -- AMR',
'end is_media;',
'',
'----------------------------------------------------------------------------',
'-- AJAX: one part of a recording (base64 pieces in f01)',
'----------------------------------------------------------------------------',
'procedure save_part ( p_item in apex_plugin.t_item )',
'is',
'    l_parts  varchar2(255) := coll(p_item) || c_parts;',
'    l_item   varchar2(255) := p_item.name;',
'    l_token  varchar2(64)  := apex_application.g_x02;',
'    l_blob   blob;',
'    l_raw    raw(32767);',
'    l_total  number;',
'    l_others pls_integer;',
'    l_old    apex_t_number;',
'    l_seq    number;',
'begin',
'    check_token(l_token);',
'    ensure(l_parts);',
'    -- parts of uploads that never finished',
'    select seq_id bulk collect into l_old from apex_collections where collection_name = l_parts and d001 < sysdate - 1/24;',
'    for i in 1 .. l_old.count loop',
'        apex_collection.delete_member(l_parts, l_old(i));',
'    end loop;',
'',
'    select nvl(sum(dbms_lob.getlength(blob001)), 0) into l_total',
'      from apex_collections',
'     where collection_name = l_parts and c004 = l_item and c001 = l_token;',
'    select count(distinct c001) into l_others',
'      from apex_collections',
'     where collection_name = l_parts and c004 = l_item and c001 <> l_token;',
'    if l_others >= c_uploads then',
'        json_error(msg(''BUSY_UPLOADS'', ''Other recordings are still being saved. Please wait a moment.''));',
'        return;',
'    end if;',
'',
'    dbms_lob.createtemporary(l_blob, true, dbms_lob.call);',
'    for i in 1 .. apex_application.g_f01.count loop',
'        if apex_application.g_f01(i) is not null then',
'            l_raw := utl_encode.base64_decode(utl_raw.cast_to_raw(apex_application.g_f01(i)));',
'            dbms_lob.writeappend(l_blob, utl_raw.length(l_raw), l_raw);',
'        end if;',
'    end loop;',
'',
'    if l_total + dbms_lob.getlength(l_blob) > max_bytes(p_item) * c_allow then',
'        apex_collection.delete_members(p_collection_name => l_parts, p_attr_number => 1, p_attr_value => l_token);',
'        json_error(msg(''TOO_LARGE'', ''The file is larger than the maximum of %0 MB.'', attr(p_item, 2)));',
'        return;',
'    end if;',
'',
'    l_seq := apex_collection.add_member(',
'                 p_collection_name => l_parts,',
'                 p_c001            => l_token,',
'                 p_c004            => l_item,',
'                 p_n001            => to_number(apex_application.g_x03),',
'                 p_d001            => sysdate,',
'                 p_blob001         => l_blob );',
'    apex_json.open_object;',
'    apex_json.write(''ok'', true);',
'    apex_json.close_object;',
'end save_part;',
'',
'----------------------------------------------------------------------------',
'-- Transcription = Server: the developer''s PL/SQL turns the recording into text',
'----------------------------------------------------------------------------',
'function transcribe ( p_item in apex_plugin.t_item, p_seq in number, p_mime in varchar2, p_lang in varchar2 ) return varchar2',
'is',
'    l_params apex_exec.t_parameters;',
'begin',
'    apex_exec.add_parameter(l_params, ''COLLECTION_NAME'', coll(p_item));',
'    apex_exec.add_parameter(l_params, ''SEQ_ID'', p_seq);',
'    apex_exec.add_parameter(l_params, ''MIME_TYPE'', p_mime);',
'    apex_exec.add_parameter(l_params, ''LANGUAGE'', p_lang);',
'    apex_exec.add_parameter(l_params, ''TRANSCRIPT'', '' '');',
'    apex_exec.execute_plsql(p_plsql_code => attr(p_item, 24), p_auto_bind_items => true, p_sql_parameters => l_params);',
'    return trim(apex_exec.get_parameter_varchar2(l_params, ''TRANSCRIPT''));',
'end transcribe;',
'',
'----------------------------------------------------------------------------',
'-- AJAX: all parts arrived - join them into one collection member',
'----------------------------------------------------------------------------',
'procedure finish ( p_item in apex_plugin.t_item )',
'is',
'    l_coll  varchar2(255) := coll(p_item);',
'    l_parts varchar2(255) := l_coll || c_parts;',
'    l_item  varchar2(255) := p_item.name;',
'    l_token varchar2(64)  := apex_application.g_x02;',
'    l_mine  apex_t_number := seqs(apex_application.g_x05);',
'    l_max   pls_integer   := greatest(1, num(attr(p_item, 5), 1));',
'    l_meta  json_object_t;',
'    l_mime  varchar2(255);',
'    l_name  varchar2(400);',
'    l_kind  varchar2(10);',
'    l_mode  varchar2(30)  := modes(p_item);',
'    l_dur   number;',
'    l_w     number;',
'    l_h     number;',
'    l_text  clob;',
'    l_said  varchar2(32767);',
'    l_blob  blob;',
'    l_count pls_integer := 0;',
'    l_have  pls_integer := 0;',
'    l_seq   number;',
'begin',
'    check_token(l_token);',
'    l_meta := json_object_t.parse(nvl(apex_application.g_x03, ''{}''));',
'    l_mime := lower(trim(regexp_substr(l_meta.get_string(''mime''), ''^[^;]+'')));',
'    l_name := l_meta.get_string(''name'');',
'    l_dur  := l_meta.get_number(''duration'');',
'    l_w    := l_meta.get_number(''width'');',
'    l_h    := l_meta.get_number(''height'');',
'    l_text := l_meta.get_clob(''transcript'');',
'    l_kind := case when l_mime like ''audio/%'' then ''AUDIO'' when l_mime like ''video/%'' then ''VIDEO'' when l_mime like ''image/%'' then ''IMAGE'' end;',
'',
'    ensure(l_parts);',
'    dbms_lob.createtemporary(l_blob, true, dbms_lob.call);',
'    for r in ( select blob001',
'                 from apex_collections',
'                where collection_name = l_parts',
'                  and c001 = l_token',
'                  and c004 = l_item',
'                order by n001 )',
'    loop',
'        if dbms_lob.getlength(r.blob001) > 0 then',
'            dbms_lob.append(l_blob, r.blob001);',
'        end if;',
'        l_count := l_count + 1;',
'    end loop;',
'    apex_collection.delete_members(p_collection_name => l_parts, p_attr_number => 1, p_attr_value => l_token);',
'',
'    if l_kind is null or not regexp_like(l_mime, ''^(audio|video|image)/[a-z0-9.+-]{1,60}$'')',
'       or instr('':'' || l_mode || '':'', '':'' || l_kind || '':'') = 0 or not is_media(l_blob, l_kind)',
'    then',
'        json_error(msg(''WRONG_TYPE'', ''This kind of file is not allowed here.''));',
'        return;',
'    end if;',
'    if l_count = 0 or l_count <> to_number(apex_application.g_x04) or dbms_lob.getlength(l_blob) = 0 then',
'        json_error(msg(''UPLOAD_INCOMPLETE'', ''The upload was incomplete. Please try again.''));',
'        return;',
'    end if;',
'    if dbms_lob.getlength(l_blob) > max_bytes(p_item) * c_allow then',
'        json_error(msg(''TOO_LARGE'', ''The file is larger than the maximum of %0 MB.'', attr(p_item, 2)));',
'        return;',
'    end if;',
'',
'    -- Maximum Recordings: the item''s current recordings, and a hard cap for the session',
'    ensure(l_coll);',
'    select count(*), count(case when seq_id in (select column_value from table(l_mine)) then 1 end)',
'      into l_count, l_have',
'      from apex_collections',
'     where collection_name = l_coll',
'       and c004 = l_item;',
'    if l_have >= l_max or l_count >= l_max + c_spare then',
'        json_error(msg(''MAX_COUNT'', ''The maximum of %0 has been reached. Delete one to add another.'', l_max));',
'        return;',
'    end if;',
'',
'    l_name := substr(regexp_replace(nvl(trim(l_name), ''recording''), ''[^[:alnum:]._ -]'', ''_''), 1, 200);',
'    l_seq := apex_collection.add_member(',
'                 p_collection_name => l_coll,',
'                 p_c001            => l_name,',
'                 p_c002            => l_mime,',
'                 p_c003            => l_kind,',
'                 p_c004            => l_item,',
'                 p_n001            => dbms_lob.getlength(l_blob),',
'                 p_n002            => round(l_dur, 1),',
'                 p_n003            => round(l_w),',
'                 p_n004            => round(l_h),',
'                 p_d001            => sysdate,',
'                 p_clob001         => case when dbms_lob.getlength(l_text) > 0 then l_text end,',
'                 p_blob001         => l_blob );',
'',
'    if attr(p_item, 19) = ''SERVER'' and attr(p_item, 24) is not null and l_kind = ''AUDIO'' then',
'        begin',
'            l_said := transcribe(p_item, l_seq, l_mime, apex_application.g_x06);',
'            if l_said is not null then',
'                apex_collection.update_member_attribute(p_collection_name => l_coll, p_seq => l_seq, p_clob_number => 1, p_clob_value => l_said);',
'                l_text := l_said;',
'            end if;',
'        exception',
'            when others then',
'                apex_debug.error(''MediaPlus %s transcription: %s'', l_item, sqlerrm);',
'        end;',
'    end if;',
'',
'    apex_json.open_object;',
'    apex_json.write(''seq'', l_seq);',
'    apex_json.write(''name'', l_name);',
'    apex_json.write(''mime'', l_mime);',
'    apex_json.write(''kind'', l_kind);',
'    apex_json.write(''size'', dbms_lob.getlength(l_blob));',
'    apex_json.write(''duration'', round(l_dur, 1));',
'    apex_json.write(''width'', round(l_w));',
'    apex_json.write(''height'', round(l_h));',
'    if dbms_lob.getlength(l_text) > 0 then apex_json.write(''transcript'', l_text); end if;',
'    apex_json.close_object;',
'end finish;',
'',
'----------------------------------------------------------------------------',
'-- AJAX: stream a pending recording (collection) or a saved one (Saved Recordings Query)',
'----------------------------------------------------------------------------',
'procedure send_pending ( p_item in apex_plugin.t_item )',
'is',
'    l_coll varchar2(255) := coll(p_item);',
'    l_item varchar2(255) := p_item.name;',
'    l_blob blob;',
'    l_mime varchar2(255);',
'    l_name varchar2(400);',
'begin',
'    select blob001, c002, c001',
'      into l_blob, l_mime, l_name',
'      from apex_collections',
'     where collection_name = l_coll',
'       and seq_id = to_number(apex_application.g_x02)',
'       and c004 = l_item;',
'    send_blob(l_blob, l_mime, l_name);',
'exception',
'    when no_data_found or value_error or invalid_number then',
'        not_found;',
'end send_pending;',
'',
'procedure send_saved ( p_item in apex_plugin.t_item )',
'is',
'    l_ctx  apex_exec.t_context;',
'    l_row  pls_integer := 0;',
'    l_want pls_integer := to_number(apex_application.g_x02);',
'    l_blob blob;',
'    l_mime varchar2(255);',
'    l_name varchar2(400);',
'    l_cols pls_integer;',
'begin',
'    l_ctx  := apex_exec.open_query_context(p_location => apex_exec.c_location_local_db, p_sql_query => attr(p_item, 18));',
'    l_cols := apex_exec.get_column_count(l_ctx);',
'    while apex_exec.next_row(l_ctx) loop',
'        l_row := l_row + 1;',
'        if l_row = l_want then',
'            l_blob := apex_exec.get_blob(l_ctx, 1);',
'            if l_cols > 1 then l_mime := apex_exec.get_varchar2(l_ctx, 2); end if;',
'            if l_cols > 2 then l_name := apex_exec.get_varchar2(l_ctx, 3); end if;',
'            exit;',
'        end if;',
'    end loop;',
'    apex_exec.close(l_ctx);',
'    if l_blob is null or dbms_lob.getlength(l_blob) = 0 then',
'        not_found;',
'    else',
'        send_blob(l_blob, l_mime, nvl(l_name, ''recording''));',
'    end if;',
'exception',
'    when others then',
'        apex_exec.close(l_ctx);',
'        raise;',
'end send_saved;',
'',
'procedure remove ( p_item in apex_plugin.t_item )',
'is',
'    l_coll varchar2(255) := coll(p_item);',
'    l_item varchar2(255) := p_item.name;',
'    l_seq  number := to_number(apex_application.g_x02);',
'begin',
'    for r in ( select seq_id',
'                 from apex_collections',
'                where collection_name = l_coll',
'                  and seq_id = l_seq',
'                  and c004 = l_item )',
'    loop',
'        apex_collection.delete_member(l_coll, r.seq_id);',
'    end loop;',
'    apex_json.open_object;',
'    apex_json.write(''ok'', true);',
'    apex_json.close_object;',
'end remove;',
'',
'procedure ajax (',
'    p_item   in            apex_plugin.t_item,',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_param  in            apex_plugin.t_item_ajax_param,',
'    p_result in out nocopy apex_plugin.t_item_ajax_result )',
'is',
'    l_req varchar2(30) := upper(apex_application.g_x01);',
'begin',
'    if l_req = ''GET'' then',
'        send_pending(p_item);',
'        return;',
'    elsif l_req = ''SAVED'' then',
'        if attr(p_item, 18) is not null then',
'            send_saved(p_item);',
'        else',
'            not_found;',
'        end if;',
'        return;',
'    end if;',
'',
'    json_header;',
'    if l_req is null or l_req not in (''PART'', ''FINISH'', ''DELETE'') then',
'        json_error(''MediaPlus: request not allowed'');',
'    elsif l_req = ''PART'' then',
'        save_part(p_item);',
'    elsif l_req = ''FINISH'' then',
'        finish(p_item);',
'    else',
'        remove(p_item);',
'    end if;',
'exception',
'    when others then',
'        -- details go to the debug log, not to the browser',
'        apex_debug.error(''MediaPlus %s %s: %s %s'', p_item.name, l_req, sqlerrm, dbms_utility.format_error_backtrace);',
'        if l_req in (''GET'', ''SAVED'') then',
'            not_found;',
'            return;',
'        end if;',
'        json_error(msg(''SERVER_ERROR'', ''This could not be saved because of a server error. Please try again.''));',
'end ajax;',
'',
'----------------------------------------------------------------------------',
'-- render',
'----------------------------------------------------------------------------',
'procedure render (',
'    p_item   in            apex_plugin.t_item,',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_param  in            apex_plugin.t_item_render_param,',
'    p_result in out nocopy apex_plugin.t_item_render_result )',
'is',
'    l_name  varchar2(255) := p_item.name;',
'    l_coll  varchar2(255) := coll(p_item);',
'    l_seqs  apex_t_number := seqs(p_param.value);',
'    l_old   apex_t_number;',
'    l_value varchar2(4000);',
'    l_ro    boolean := p_param.is_readonly or p_param.is_printer_friendly;',
'    l_json  clob;',
'    l_ctx   apex_exec.t_context;',
'    l_cols  pls_integer;',
'    l_blob  blob;',
'    l_row   pls_integer := 0;',
'begin',
'    -- forget recordings nobody refers to any more; only after an hour, so a second tab of the same session is safe',
'    if apex_collection.collection_exists(l_coll) then',
'        select seq_id bulk collect into l_old',
'          from apex_collections',
'         where collection_name = l_coll',
'           and c004 = l_name',
'           and d001 < sysdate - 1/24',
'           and seq_id not in (select column_value from table(l_seqs));',
'        for i in 1 .. l_old.count loop',
'            apex_collection.delete_member(l_coll, l_old(i));',
'        end loop;',
'    end if;',
'    if apex_collection.collection_exists(l_coll || c_parts) then',
'        select seq_id bulk collect into l_old',
'          from apex_collections',
'         where collection_name = l_coll || c_parts',
'           and d001 < sysdate - 1/24;',
'        for i in 1 .. l_old.count loop',
'            apex_collection.delete_member(l_coll || c_parts, l_old(i));',
'        end loop;',
'    end if;',
'',
'    apex_json.initialize_clob_output;',
'    apex_json.open_object;',
'    apex_json.write(''item'', l_name);',
'    apex_json.write(''label'', p_item.plain_label);',
'    apex_json.write(''ajax'', apex_plugin.get_ajax_identifier);',
'    apex_json.write(''mode'', modes(p_item));',
'    apex_json.write(''maxBytes'', max_bytes(p_item));',
'    apex_json.write(''allowance'', c_allow);',
'    apex_json.write(''warnPct'', num(attr(p_item, 3), 80));',
'    apex_json.write(''maxDuration'', num(attr(p_item, 4), 0));',
'    apex_json.write(''maxCount'', num(attr(p_item, 5), 1));',
'    apex_json.write(''quality'', nvl(attr(p_item, 6), ''BALANCED''));',
'    apex_json.write(''audioKbps'', num(attr(p_item, 7), 48));',
'    apex_json.write(''videoHeight'', num(attr(p_item, 8), 480));',
'    apex_json.write(''videoKbps'', num(attr(p_item, 9), 900));',
'    apex_json.write(''fps'', num(attr(p_item, 10), 24));',
'    apex_json.write(''audioOptions'', nvl(attr(p_item, 11), ''-''));',
'    apex_json.write(''format'', nvl(attr(p_item, 12), ''AUTO''));',
'    apex_json.write(''features'', nvl(attr(p_item, 13), ''-''));',
'    apex_json.write(''camera'', nvl(attr(p_item, 14), ''environment''));',
'    apex_json.write(''style'', nvl(attr(p_item, 15), ''FULL''));',
'    apex_json.write(''fileName'', nvl(attr(p_item, 17), ''#ITEM#-#TIMESTAMP#''));',
'    apex_json.write(''transcription'', case when attr(p_item, 19) = ''SERVER'' and attr(p_item, 24) is null then ''NONE'' else nvl(attr(p_item, 19), ''NONE'') end);',
'    apex_json.write(''transcriptLanguages'', attr(p_item, 20));',
'    apex_json.write(''transcriptItem'', attr(p_item, 21));',
'    apex_json.write(''allowRequests'', nvl(attr(p_item, 22), ''CANCEL,DELETE''));',
'    apex_json.write(''buttons'', nvl(attr(p_item, 23), ''ROUNDED''));',
'    apex_json.write(''imageFormat'', nvl(attr(p_item, 25), ''JPEG''));',
'    apex_json.write(''imageQuality'', num(attr(p_item, 26), 85));',
'    apex_json.write(''imageMaxSide'', num(attr(p_item, 27), 1920));',
'    apex_json.write(''imageTools'', nvl(attr(p_item, 28), ''-''));',
'    apex_json.write(''cropRatio'', nvl(attr(p_item, 29), ''FREE''));',
'    apex_json.write(''appId'', v(''APP_ID''));',
'    apex_json.write(''pageId'', v(''APP_PAGE_ID''));',
'    apex_json.write(''readOnly'', l_ro);',
'',
'    -- recordings of this item still waiting in the collection (e.g. after a validation error)',
'    apex_json.open_array(''items'');',
'    if apex_collection.collection_exists(l_coll) then',
'        for r in ( select seq_id, c001, c002, c003, n001, n002, n003, n004, clob001',
'                     from apex_collections',
'                    where collection_name = l_coll',
'                      and c004 = l_name',
'                      and seq_id in (select column_value from table(l_seqs))',
'                    order by seq_id )',
'        loop',
'            l_value := l_value || case when l_value is not null then '':'' end || r.seq_id;',
'            apex_json.open_object;',
'            apex_json.write(''seq'', r.seq_id);',
'            apex_json.write(''name'', r.c001);',
'            apex_json.write(''mime'', r.c002);',
'            apex_json.write(''kind'', r.c003);',
'            apex_json.write(''size'', r.n001);',
'            apex_json.write(''duration'', r.n002);',
'            apex_json.write(''width'', r.n003);',
'            apex_json.write(''height'', r.n004);',
'            if r.clob001 is not null then apex_json.write(''transcript'', r.clob001); end if;',
'            apex_json.close_object;',
'        end loop;',
'    end if;',
'    apex_json.close_array;',
'',
'    -- recordings already saved in the application''s table',
'    apex_json.open_array(''saved'');',
'    if attr(p_item, 18) is not null then',
'        begin',
'            l_ctx  := apex_exec.open_query_context(p_location => apex_exec.c_location_local_db, p_sql_query => attr(p_item, 18), p_max_rows => 50);',
'            l_cols := apex_exec.get_column_count(l_ctx);',
'            while apex_exec.next_row(l_ctx) loop',
'                l_row  := l_row + 1;',
'                l_blob := apex_exec.get_blob(l_ctx, 1);',
'                if l_blob is not null and dbms_lob.getlength(l_blob) > 0 then',
'                    apex_json.open_object;',
'                    apex_json.write(''row'', l_row);',
'                    apex_json.write(''size'', dbms_lob.getlength(l_blob));',
'                    if l_cols > 1 then apex_json.write(''mime'', apex_exec.get_varchar2(l_ctx, 2)); end if;',
'                    if l_cols > 2 then apex_json.write(''name'', apex_exec.get_varchar2(l_ctx, 3)); end if;',
'                    if l_cols > 3 then apex_json.write(''duration'', apex_exec.get_number(l_ctx, 4)); end if;',
'                    if l_cols > 4 then apex_json.write(''transcript'', apex_exec.get_clob(l_ctx, 5)); end if;',
'                    apex_json.close_object;',
'                end if;',
'            end loop;',
'            apex_exec.close(l_ctx);',
'        exception',
'            when others then',
'                apex_exec.close(l_ctx);',
'                apex_debug.error(''MediaPlus %s saved recordings query: %s'', l_name, sqlerrm);',
'        end;',
'    end if;',
'    apex_json.close_array;',
'    apex_json.close_object;',
'    l_json := apex_json.get_clob_output;',
'    apex_json.free_output;',
'',
'    sys.htp.p(''<input type="hidden" id="'' || l_name || ''" name="'' || l_name || ''" value="'' || apex_escape.html_attribute(l_value) || ''">''',
'           || ''<div id="'' || l_name || ''_MPLUS" class="mplus'' || case when l_ro then '' mplus--ro'' end',
'           || ''" role="group" aria-label="'' || apex_escape.html_attribute(p_item.plain_label) || ''"></div>'');',
'    -- settings and recordings as a JSON block (transcripts can be longer than on-load code allows)',
'    sys.htp.prn(''<script type="application/json" id="'' || l_name || ''_MPLUS_CFG">'');',
'    apex_util.prn(replace(l_json, ''</'', ''<\/''), false);',
'    sys.htp.p(''</script>'');',
'',
'    apex_javascript.add_onload_code(',
'        ''mediaPlus.init(JSON.parse(document.getElementById("'' || l_name || ''_MPLUS_CFG").textContent)''',
'        || case when p_item.init_javascript_code is not null then '', '' || p_item.init_javascript_code end || '');'');',
'',
'    p_result.is_navigable     := not l_ro;',
'    p_result.navigable_dom_id := l_name || ''_MPLUS'';',
'end render;',
'',
'----------------------------------------------------------------------------',
'-- validation: every recording in the value must still be in the collection, and no more than allowed',
'----------------------------------------------------------------------------',
'procedure validation (',
'    p_item   in            apex_plugin.t_item,',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_param  in            apex_plugin.t_item_validation_param,',
'    p_result in out nocopy apex_plugin.t_item_validation_result )',
'is',
'    l_coll  varchar2(255) := coll(p_item);',
'    l_item  varchar2(255) := p_item.name;',
'    l_seqs  apex_t_number := seqs(p_param.value);',
'    l_count pls_integer := 0;',
'begin',
'    if p_param.value is null then',
'        return;',
'    end if;',
'    if apex_collection.collection_exists(l_coll) then',
'        select count(*)',
'          into l_count',
'          from apex_collections',
'         where collection_name = l_coll',
'           and c004 = l_item',
'           and seq_id in (select column_value from table(l_seqs));',
'    end if;',
'    if l_count = 0 or l_count <> l_seqs.count then',
'        p_result.message := msg(''EXPIRED'', ''%0: a recording or photo is no longer available. Please add it again.'', p_item.plain_label);',
'    elsif l_count > greatest(1, num(attr(p_item, 5), 1)) then',
'        p_result.message := msg(''TOO_MANY'', ''%0: there are more than allowed.'', p_item.plain_label);',
'    end if;',
'end validation;'))
,p_api_version=>3
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_validation_function=>'validation'
,p_item_session_state_data_type=>'VARCHAR2'
,p_standard_attributes=>'VISIBLE:FORM_ELEMENT:SESSION_STATE:READONLY:SOURCE:INIT_JAVASCRIPT_CODE'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'MediaPlus records audio and video and takes photos right in the page - on phones and desktops - and keeps each one in an APEX collection until your page process saves it into your own table. Mode can be any one, two or all three of Audio, Video and P'
||'hoto; with more than one, users pick.',
'',
'Recordings: record, pause and resume, stop, then listen to or watch it before using it. A meter shows the size used; at the Warning Threshold users are warned, and at the Maximum File Size (or Maximum Length) recording stops by itself. Quality (bit r'
||'ate, resolution, frame rate, mono) keeps files small. Recordings are repaired after recording, so they play and seek in every player (Windows Media Player, VLC, phones).',
'',
'Photos: take one with the camera or choose a file, then crop (free or a fixed shape), turn, flip, adjust brightness, contrast and colour, make it black and white, draw on it, and pick a size. The photo is saved as JPEG, WebP or PNG and compressed unt'
||'il it fits the Maximum File Size; its EXIF data (such as the location) is removed.',
'',
'The item value is the list of collection SEQ_IDs, separated by colons. Save them in a page process after the item is submitted:',
'',
'insert into my_media (title, media, mime_type, file_name, file_size, duration_sec, media_kind)',
'select :P10_TITLE, blob001, c002, c001, n001, n002, c003',
'  from apex_collections',
' where collection_name = ''MEDIAPLUS''',
'   and seq_id in (select column_value from table(apex_string.split_numbers(:P10_MEDIA, '':'')));',
'',
'Collection columns: C001 file name, C002 MIME type, C003 AUDIO, VIDEO or IMAGE, C004 item name, N001 size in bytes, N002 length in seconds, N003 / N004 photo width / height, D001 created, BLOB001 the file, CLOB001 transcript. Members nobody saved are'
||' removed after an hour.',
'',
'Saved Recordings Query shows files that are already in your table (play, view and download - e.g. on an edit page or in read-only mode).',
'',
'The camera and microphone need a secure (https) page. Without them users can still pick a file or open the phone''s own camera or recorder.',
'',
'JavaScript: mediaPlus.get("P10_MEDIA").start() / pause() / resume() / stop() / capture() / use() / discard() / kind() / state() / isBusy() / recordings(). Texts can be translated with text messages MEDIAPLUS.<KEY> (see the README).'))
,p_version_identifier=>'2.0.0'
,p_files_version=>2461346143530
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12115663493788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Capture'
,p_apexlang_name=>'mplusCapture'
,p_static_id=>'mplusCapture'
,p_display_sequence=>10
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12115972141788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Controls'
,p_apexlang_name=>'mplusControls'
,p_static_id=>'mplusControls'
,p_display_sequence=>30
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12115864076788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Photo'
,p_apexlang_name=>'mplusPhoto'
,p_static_id=>'mplusPhoto'
,p_display_sequence=>25
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12115764827788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Audio and Video Quality'
,p_apexlang_name=>'mplusQuality'
,p_static_id=>'mplusQuality'
,p_display_sequence=>20
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12116144245788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Storage'
,p_apexlang_name=>'mplusStorage'
,p_static_id=>'mplusStorage'
,p_display_sequence=>40
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(12116025892788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_title=>'Transcription'
,p_apexlang_name=>'mplusTranscription'
,p_static_id=>'mplusTranscription'
,p_display_sequence=>35
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12116267681788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'attribute_01'
,p_prompt=>'Mode'
,p_apexlang_name=>'mode'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>true
,p_default_value=>'AUDIO'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115663493788951)
,p_help_text=>'What users can add - one, two or all three. With more than one, users pick with a switch (Audio / Video / Photo); the first one ticked is selected. A video recording includes sound unless Sound in Video Recordings is unticked.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12116358313788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_display_sequence=>10
,p_display_value=>'Audio'
,p_return_value=>'AUDIO'
,p_apexlang_name=>'audio'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12116503089788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_display_sequence=>30
,p_display_value=>'Photo'
,p_return_value=>'IMAGE'
,p_apexlang_name=>'image'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12116414601788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_display_sequence=>20
,p_display_value=>'Video'
,p_return_value=>'VIDEO'
,p_apexlang_name=>'video'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12116662975788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'attribute_02'
,p_prompt=>'Maximum File Size'
,p_apexlang_name=>'maxFileSize'
,p_attribute_type=>'NUMBER'
,p_is_required=>true
,p_default_value=>'10'
,p_unit=>'MB'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12115663493788951)
,p_help_text=>'The largest file allowed, in MB (decimals such as 0.5 are fine). Recordings - a meter shows how much is used, and recording stops by itself just before this size. Photos are compressed and, if needed, made smaller until they fit. Chosen recordings ov'
||'er the limit are refused; the server checks the size again.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12116725280788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'attribute_03'
,p_prompt=>'Warning Threshold'
,p_apexlang_name=>'warningThreshold'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'80'
,p_unit=>'%'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'AUDIO,VIDEO'
,p_attribute_group_id=>wwv_flow_imp.id(12115663493788951)
,p_help_text=>'When a recording reaches this share of the Maximum File Size (or of the Maximum Length), users see a warning that recording will stop soon, the meter turns red, phones vibrate and the Size or Length Warning event fires. 100 = no warning.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12116857871788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'attribute_04'
,p_prompt=>'Maximum Length'
,p_apexlang_name=>'maxLength'
,p_attribute_type=>'INTEGER'
,p_is_required=>false
,p_unit=>'seconds'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'AUDIO,VIDEO'
,p_attribute_group_id=>wwv_flow_imp.id(12115663493788951)
,p_help_text=>'Optional time limit for recordings. Recording stops at whichever comes first, this length or the Maximum File Size. Pauses do not count.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12116951105788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'attribute_05'
,p_prompt=>'Maximum Files'
,p_apexlang_name=>'maxFiles'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'1'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12115663493788951)
,p_help_text=>'How many recordings and photos the item can hold together, e.g. 3 photos of a damage. Each one has its own size limit. Users delete one to add another.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12117034418788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>10
,p_static_id=>'attribute_06'
,p_prompt=>'Quality'
,p_apexlang_name=>'quality'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'BALANCED'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'AUDIO,VIDEO'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Lower quality = smaller files, so more fits under the Maximum File Size. Approximate size per minute:',
'Small: audio 24 kbps (0.2 MB), video 360p 15 fps 350 kbps (2.8 MB)',
'Balanced: audio 48 kbps (0.35 MB), video 480p 24 fps 900 kbps (7 MB)',
'High: audio 128 kbps (1 MB), video 720p 30 fps 2.5 Mbps (19 MB)',
'Custom: set the bit rates, resolution and frame rate yourself.',
'The hint under the Record button tells users about how long they can record.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117248652788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_display_sequence=>20
,p_display_value=>'Balanced'
,p_return_value=>'BALANCED'
,p_apexlang_name=>'balanced'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117421113788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_display_sequence=>40
,p_display_value=>'Custom'
,p_return_value=>'CUSTOM'
,p_apexlang_name=>'custom'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117348073788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_display_sequence=>30
,p_display_value=>'High Quality'
,p_return_value=>'HIGH'
,p_apexlang_name=>'high'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117177181788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_display_sequence=>10
,p_display_value=>'Small Files'
,p_return_value=>'SMALL'
,p_apexlang_name=>'small'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12117593088788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>20
,p_static_id=>'attribute_07'
,p_prompt=>'Audio Bit Rate'
,p_apexlang_name=>'audioBitrate'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'48'
,p_unit=>'kbps'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'CUSTOM'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>'16 - 32 kbps is fine for speech, 64 - 128 kbps for music.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12117619305788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>30
,p_static_id=>'attribute_08'
,p_prompt=>'Video Resolution'
,p_apexlang_name=>'videoResolution'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'480'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'CUSTOM'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>'The height the camera is asked for. Devices may deliver the nearest size they support.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118109690788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117619305788951)
,p_display_sequence=>50
,p_display_value=>'1080p (Full HD)'
,p_return_value=>'1080'
,p_apexlang_name=>'h1080'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117759082788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117619305788951)
,p_display_sequence=>10
,p_display_value=>'240p'
,p_return_value=>'240'
,p_apexlang_name=>'h240'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117860191788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117619305788951)
,p_display_sequence=>20
,p_display_value=>'360p'
,p_return_value=>'360'
,p_apexlang_name=>'h360'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12117948151788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117619305788951)
,p_display_sequence=>30
,p_display_value=>'480p'
,p_return_value=>'480'
,p_apexlang_name=>'h480'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118074490788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12117619305788951)
,p_display_sequence=>40
,p_display_value=>'720p (HD)'
,p_return_value=>'720'
,p_apexlang_name=>'h720'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12118218043788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>40
,p_static_id=>'attribute_09'
,p_prompt=>'Video Bit Rate'
,p_apexlang_name=>'videoBitrate'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'900'
,p_unit=>'kbps'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'CUSTOM'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>'Has the biggest effect on file size. 1,000 kbps is about 7.5 MB per minute.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12118322485788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>50
,p_static_id=>'attribute_10'
,p_prompt=>'Frame Rate'
,p_apexlang_name=>'frameRate'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'24'
,p_unit=>'fps'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12117034418788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'CUSTOM'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12118449873788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>60
,p_static_id=>'attribute_11'
,p_prompt=>'Audio Options'
,p_apexlang_name=>'audioOptions'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'mono:noiseSuppression:autoGainControl:videoSound'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'AUDIO,VIDEO'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>'Mono halves the audio data and suits speech. Noise Suppression and Automatic Gain are done by the browser and make voices clearer. Echo Cancellation is only needed when sound plays while recording (a call); on iPhones it switches the microphone to ph'
||'one-call quality, so leave it off for voice notes. Untick Sound in Video Recordings for silent video (smaller files, no microphone prompt). Bluetooth headsets (AirPods) record in phone-call quality whatever is set here.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118869847788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12118449873788951)
,p_display_sequence=>40
,p_display_value=>'Automatic Gain'
,p_return_value=>'autoGainControl'
,p_apexlang_name=>'autoGainControl'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118714259788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12118449873788951)
,p_display_sequence=>30
,p_display_value=>'Echo Cancellation'
,p_return_value=>'echoCancellation'
,p_apexlang_name=>'echoCancellation'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118560174788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12118449873788951)
,p_display_sequence=>10
,p_display_value=>'Mono'
,p_return_value=>'mono'
,p_apexlang_name=>'mono'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118651938788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12118449873788951)
,p_display_sequence=>20
,p_display_value=>'Noise Suppression'
,p_return_value=>'noiseSuppression'
,p_apexlang_name=>'noiseSuppression'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12118968791788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12118449873788951)
,p_display_sequence=>50
,p_display_value=>'Sound in Video Recordings'
,p_return_value=>'videoSound'
,p_apexlang_name=>'videoSound'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12119002666788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>70
,p_static_id=>'attribute_12'
,p_prompt=>'File Format'
,p_apexlang_name=>'fileFormat'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'AUTO'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'AUDIO,VIDEO'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115764827788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The format the browser is asked to record in; it falls back to what it supports, and the real MIME type is saved with every recording.',
'Automatic (recommended): MP4 - video as MP4 (H.264 / AAC), audio as M4A (AAC). These open everywhere: iPhone and Mac, Windows Media Player (also legacy), Android, VLC. Chrome records AAC at about 100 kbps whatever the bit rate (about 0.75 MB per minu'
||'te). Firefox cannot write MP4 and records WebM.',
'Smallest (WebM): WebM / Opus - smallest (an Opus voice note at 24 kbps is a quarter of the size) and plays in browsers and VLC, but saved files do not open on iPhones or in Windows Media Player.',
'No browser can record MP3. Every recording is repaired after recording - a duration and a seek index are written - so it plays and seeks in every player.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12119177567788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12119002666788951)
,p_display_sequence=>10
,p_display_value=>'Automatic (MP4 / M4A - plays everywhere)'
,p_return_value=>'AUTO'
,p_apexlang_name=>'auto'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12119326169788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12119002666788951)
,p_display_sequence=>30
,p_display_value=>'Smallest (WebM)'
,p_return_value=>'WEBM'
,p_apexlang_name=>'webm'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12121469999788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>10
,p_static_id=>'attribute_13'
,p_prompt=>'Features'
,p_apexlang_name=>'features'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'pause:preview:levelMeter:switchCamera:mirror:download:confirmDelete'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115972141788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Pause and Resume: a Pause button while recording.',
'Review Before Use: after Stop, users listen to or watch the recording and choose Use, Record Again or Discard. Without it a recording is saved as soon as it stops. Photos are always reviewed when an Editing Tool is on.',
'Countdown: 3 - 2 - 1 before recording starts.',
'Level Meter: live sound level (a waveform for audio, a bar on video).',
'Switch Camera: front / back camera button, when the device has more than one.',
'Mirror Front Camera: shows the selfie preview mirrored, like a phone camera (the recording or photo is not mirrored).',
'Choose a File: users may also pick an existing file of an allowed kind (same limits; large photos are made smaller).',
'Download: download buttons.',
'Confirm Delete: asks before something is deleted or discarded.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122354504788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>90
,p_display_value=>'Confirm Delete'
,p_return_value=>'confirmDelete'
,p_apexlang_name=>'confirmDelete'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121738787788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>30
,p_display_value=>'Countdown'
,p_return_value=>'countdown'
,p_apexlang_name=>'countdown'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122220157788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>80
,p_display_value=>'Download'
,p_return_value=>'download'
,p_apexlang_name=>'download'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121884265788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>40
,p_display_value=>'Level Meter'
,p_return_value=>'levelMeter'
,p_apexlang_name=>'levelMeter'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122066262788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>60
,p_display_value=>'Mirror Front Camera'
,p_return_value=>'mirror'
,p_apexlang_name=>'mirror'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121521170788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>10
,p_display_value=>'Pause and Resume'
,p_return_value=>'pause'
,p_apexlang_name=>'pause'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121653378788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>20
,p_display_value=>'Review Before Use'
,p_return_value=>'preview'
,p_apexlang_name=>'preview'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121945709788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>50
,p_display_value=>'Switch Camera'
,p_return_value=>'switchCamera'
,p_apexlang_name=>'switchCamera'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122102374788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12121469999788951)
,p_display_sequence=>70
,p_display_value=>'Choose a File'
,p_return_value=>'upload'
,p_apexlang_name=>'upload'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12122459546788952)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>20
,p_static_id=>'attribute_14'
,p_prompt=>'Camera'
,p_apexlang_name=>'camera'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'environment'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'VIDEO,IMAGE'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115972141788951)
,p_help_text=>'The camera that opens first on phones and tablets, for video and photos. Laptops use their only camera.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122530941788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12122459546788952)
,p_display_sequence=>10
,p_display_value=>'Back'
,p_return_value=>'environment'
,p_apexlang_name=>'environment'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122670106788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12122459546788952)
,p_display_sequence=>20
,p_display_value=>'Front (selfie)'
,p_return_value=>'user'
,p_apexlang_name=>'user'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12122780809788952)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>30
,p_static_id=>'attribute_15'
,p_prompt=>'Display Style'
,p_apexlang_name=>'displayStyle'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'FULL'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115972141788951)
,p_help_text=>'Compact uses a slim waveform for audio, like a voice note - good on forms and phones.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122916719788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12122780809788952)
,p_display_sequence=>20
,p_display_value=>'Compact'
,p_return_value=>'COMPACT'
,p_apexlang_name=>'compact'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12122831226788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12122780809788952)
,p_display_sequence=>10
,p_display_value=>'Standard'
,p_return_value=>'FULL'
,p_apexlang_name=>'full'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123463596788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>16
,p_display_sequence=>10
,p_static_id=>'attribute_16'
,p_prompt=>'Collection Name'
,p_apexlang_name=>'collectionName'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_default_value=>'MEDIAPLUS'
,p_max_length=>100
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12116144245788951)
,p_text_case=>'UPPER'
,p_help_text=>'The APEX collection that holds recordings and photos until your page process saves them. One collection can serve every MediaPlus item - C004 holds the item name, and the item value lists the SEQ_IDs of its files. Parts of uploads in progress use a s'
||'econd collection with $PARTS added to the name.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123522935788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>17
,p_display_sequence=>20
,p_static_id=>'attribute_17'
,p_prompt=>'File Name'
,p_apexlang_name=>'fileName'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_default_value=>'#ITEM#-#TIMESTAMP#'
,p_max_length=>200
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12116144245788951)
,p_help_text=>'Name for new recordings and photos (stored in C001); the extension (.webm, .mp4, .m4a, .jpg ...) is added from the format. Substitutions: #ITEM# (item name in lower case), #TIMESTAMP# (20261029-143005), #KIND# (audio / video / image), #N# (number of '
||'the file in the item). Chosen files keep their own name.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123664140788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>18
,p_display_sequence=>30
,p_static_id=>'attribute_18'
,p_prompt=>'Saved Files Query'
,p_apexlang_name=>'savedFilesQuery'
,p_attribute_type=>'SQL'
,p_is_required=>false
,p_sql_min_column_count=>1
,p_sql_max_column_count=>5
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12116144245788951)
,p_help_text=>'Optional. Recordings and photos already saved in your table, shown above the new ones with play / view and download buttons - e.g. on an edit page, or with the item read-only to just show them. Columns in this order: the BLOB, then optionally MIME ty'
||'pe, file name, length in seconds and transcript. Example: select media, mime_type, file_name, duration_sec, transcript from my_media where request_id = :P10_ID order by created_on. Up to 50 rows.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123703299788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>19
,p_display_sequence=>10
,p_static_id=>'attribute_19'
,p_prompt=>'Transcription'
,p_apexlang_name=>'transcription'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'NONE'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12116025892788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'For audio recordings.',
'Live: transcribed while users speak, by the browser''s speech recognition (Chrome, Edge, Safari - free; Chrome sends the audio to Google''s speech service). The text appears under the waveform; in Review Before Use users can correct it - or type it whe'
||'n the browser cannot transcribe. Not available in Firefox.',
'Server: your Transcription Code (PL/SQL) turns each audio recording into text when it is saved - call the speech service you choose (OCI Speech, Whisper, Azure ...). Works in every browser; the audio only goes where your code sends it.',
'The transcript is saved in CLOB001 of the collection and, if set, in the Transcript Item.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12123967526788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_display_sequence=>20
,p_display_value=>'Live (browser speech recognition)'
,p_return_value=>'LIVE'
,p_apexlang_name=>'live'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12123845354788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_display_sequence=>10
,p_display_value=>'None'
,p_return_value=>'NONE'
,p_apexlang_name=>'none'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12124083704788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_display_sequence=>30
,p_display_value=>'Server (your PL/SQL)'
,p_return_value=>'SERVER'
,p_apexlang_name=>'server'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12124191549788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>20
,p_display_sequence=>20
,p_static_id=>'attribute_20'
,p_prompt=>'Languages'
,p_apexlang_name=>'transcriptionLanguages'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'en-US'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'LIVE,SERVER'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12116025892788951)
,p_help_text=>'English (US), Arabic, or both. With both, users pick the language next to the Record button (their choice is remembered); English is the default. Nothing ticked = the page language (Arabic pages Arabic, otherwise English).'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12124329609788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12124191549788960)
,p_display_sequence=>20
,p_display_value=>'Arabic'
,p_return_value=>'ar-SA'
,p_apexlang_name=>'arSa'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12124278273788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12124191549788960)
,p_display_sequence=>10
,p_display_value=>'English (US)'
,p_return_value=>'en-US'
,p_apexlang_name=>'enUs'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12124430667788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>21
,p_display_sequence=>30
,p_static_id=>'attribute_21'
,p_prompt=>'Transcript Item'
,p_apexlang_name=>'transcriptItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'LIVE,SERVER'
,p_attribute_group_id=>wwv_flow_imp.id(12116025892788951)
,p_help_text=>'Optional page item (e.g. a Textarea) that receives the transcripts of the item''s recordings, one paragraph each, whenever a recording is used or deleted - so users can edit the text and it is submitted with the page. Text the user changed is kept; ne'
||'w transcripts are added below it.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123076881788952)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>22
,p_display_sequence=>40
,p_static_id=>'attribute_22'
,p_prompt=>'Allow Submit for Requests'
,p_apexlang_name=>'allowSubmitRequests'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'CANCEL,DELETE'
,p_max_length=>200
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(12115972141788951)
,p_text_case=>'UPPER'
,p_help_text=>'While a recording is running, or a recording or photo waits to be used, the page cannot be submitted - users see a message instead. Requests (button names) listed here, separated by commas, still submit, and what was not used is dropped - e.g. CANCEL'
||',DELETE.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12123137224788952)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>23
,p_display_sequence=>50
,p_static_id=>'attribute_23'
,p_prompt=>'Button Style'
,p_apexlang_name=>'buttonStyle'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'ROUNDED'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115972141788951)
,p_help_text=>'Rounded uses the plug-in''s own pill buttons (in the theme''s colours). Theme uses Universal Theme buttons, so they follow Theme Roller and your button styles exactly.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12123232730788952)
,p_plugin_attribute_id=>wwv_flow_imp.id(12123137224788952)
,p_display_sequence=>10
,p_display_value=>'Rounded'
,p_return_value=>'ROUNDED'
,p_apexlang_name=>'rounded'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12123375920788960)
,p_plugin_attribute_id=>wwv_flow_imp.id(12123137224788952)
,p_display_sequence=>20
,p_display_value=>'Theme Buttons'
,p_return_value=>'THEME'
,p_apexlang_name=>'theme'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12124523124788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>24
,p_display_sequence=>40
,p_static_id=>'attribute_24'
,p_prompt=>'Transcription Code'
,p_apexlang_name=>'transcriptionCode'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12123703299788960)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'SERVER'
,p_attribute_group_id=>wwv_flow_imp.id(12116025892788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Runs on the server for every audio recording, right after it is uploaded. Read the recording from the collection and set :TRANSCRIPT (up to 32767 characters). Binds: :COLLECTION_NAME, :SEQ_ID, :MIME_TYPE, :LANGUAGE (en-US or ar-SA), :TRANSCRIPT; page'
||' items as usual. Errors are written to the debug log and the recording is kept without a transcript.',
'',
'declare',
'    l_media blob;',
'begin',
'    select blob001 into l_media',
'      from apex_collections',
'     where collection_name = :COLLECTION_NAME and seq_id = :SEQ_ID;',
'    :TRANSCRIPT := my_speech_pkg.transcribe(l_media, :MIME_TYPE, :LANGUAGE);',
'end;'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12119431393788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>25
,p_display_sequence=>10
,p_static_id=>'attribute_25'
,p_prompt=>'Image Format'
,p_apexlang_name=>'imageFormat'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'JPEG'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'IMAGE'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115864076788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The format photos are saved in (MIME type in C002).',
'JPEG: smallest for photos, opens everywhere.',
'WebP: about 25 - 30% smaller than JPEG at the same quality; browsers that cannot write WebP (old Safari) save JPEG.',
'PNG: lossless - for screenshots and documents with text, much larger for photos.',
'Re-saving a photo removes its EXIF data, such as the location.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12119563130788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12119431393788951)
,p_display_sequence=>10
,p_display_value=>'JPEG'
,p_return_value=>'JPEG'
,p_apexlang_name=>'jpeg'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12119765031788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12119431393788951)
,p_display_sequence=>30
,p_display_value=>'PNG'
,p_return_value=>'PNG'
,p_apexlang_name=>'png'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12119658741788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12119431393788951)
,p_display_sequence=>20
,p_display_value=>'WebP'
,p_return_value=>'WEBP'
,p_apexlang_name=>'webp'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12119836497788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>26
,p_display_sequence=>20
,p_static_id=>'attribute_26'
,p_prompt=>'Image Quality'
,p_apexlang_name=>'imageQuality'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'85'
,p_unit=>'%'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12119431393788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'NOT_EQUALS'
,p_depending_on_expression=>'PNG'
,p_attribute_group_id=>wwv_flow_imp.id(12115864076788951)
,p_help_text=>'JPEG / WebP quality, 30 - 100. 80 - 90 looks the same as the original at a fraction of the size. When a photo is over the Maximum File Size, the quality is lowered (to 50 at most), then the photo is made smaller, until it fits.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12119936445788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>27
,p_display_sequence=>30
,p_static_id=>'attribute_27'
,p_prompt=>'Maximum Photo Size'
,p_apexlang_name=>'maxPhotoSize'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'1920'
,p_unit=>'px'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'IMAGE'
,p_attribute_group_id=>wwv_flow_imp.id(12115864076788951)
,p_help_text=>'The longest side of a saved photo, in pixels; larger photos are scaled down (never up). 1920 is sharp on any screen, 1280 is plenty for forms, 3000+ keeps detail for printing. With the Resize tool users can choose a smaller size.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12120029226788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>28
,p_display_sequence=>40
,p_static_id=>'attribute_28'
,p_prompt=>'Editing Tools'
,p_apexlang_name=>'editingTools'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'crop:rotate:flip:adjust:resize'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'IMAGE'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115864076788951)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Tools in the photo editor, shown after a photo is taken or chosen.',
'Crop: a crop box with handles (drag, or arrow keys / Shift + arrows); users pick Free, 1:1, 4:3, 3:4, 16:9 or 9:16.',
'Rotate: turn left / right by 90 degrees. Flip: mirror left - right.',
'Adjust: brightness, contrast and colour, and Black and White.',
'Draw: mark things on the photo in red, yellow, white or black, with Undo.',
'Resize: users choose a smaller size than Maximum Photo Size.',
'Without any tool (and without Review Before Use) a photo is saved as soon as it is taken - still resized and compressed.'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120474221788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>40
,p_display_value=>'Adjust'
,p_return_value=>'adjust'
,p_apexlang_name=>'adjust'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120177175788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>10
,p_display_value=>'Crop'
,p_return_value=>'crop'
,p_apexlang_name=>'crop'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120564492788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>50
,p_display_value=>'Draw'
,p_return_value=>'draw'
,p_apexlang_name=>'draw'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120322874788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>30
,p_display_value=>'Flip'
,p_return_value=>'flip'
,p_apexlang_name=>'flip'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120673211788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>60
,p_display_value=>'Resize'
,p_return_value=>'resize'
,p_apexlang_name=>'resize'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120271360788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120029226788951)
,p_display_sequence=>20
,p_display_value=>'Rotate'
,p_return_value=>'rotate'
,p_apexlang_name=>'rotate'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(12120714220788951)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>29
,p_display_sequence=>50
,p_static_id=>'attribute_29'
,p_prompt=>'Crop Shape'
,p_apexlang_name=>'cropShape'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'FREE'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(12116267681788951)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'IMAGE'
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(12115864076788951)
,p_help_text=>'Free lets users crop as they like (with the Crop tool). A fixed shape - e.g. 1:1 for profile pictures, 3:4 for ID photos - always applies, with or without the Crop tool; users move and resize the box but keep the shape.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120883722788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>10
,p_display_value=>'Free (users choose)'
,p_return_value=>'FREE'
,p_apexlang_name=>'free'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121070575788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>30
,p_display_value=>'Landscape (4:3)'
,p_return_value=>'4:3'
,p_apexlang_name=>'landscape43'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121156266788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>40
,p_display_value=>'Portrait (3:4)'
,p_return_value=>'3:4'
,p_apexlang_name=>'portrait34'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12120997948788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>20
,p_display_value=>'Square (1:1)'
,p_return_value=>'1:1'
,p_apexlang_name=>'square'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121389272788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>60
,p_display_value=>'Tall (9:16)'
,p_return_value=>'9:16'
,p_apexlang_name=>'tall'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(12121295448788951)
,p_plugin_attribute_id=>wwv_flow_imp.id(12120714220788951)
,p_display_sequence=>50
,p_display_value=>'Wide (16:9)'
,p_return_value=>'16:9'
,p_apexlang_name=>'wide'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125270368788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediapluscapture'
,p_display_name=>'Photo Taken'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125504322788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplusdelete'
,p_display_name=>'Media Deleted'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125422821788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplusdiscard'
,p_display_name=>'Media Discarded'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125604926788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediapluserror'
,p_display_name=>'Media Error'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125187581788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediapluslimit'
,p_display_name=>'Limit Reached'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12124766112788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediapluspause'
,p_display_name=>'Recording Paused'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12124877923788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplusresume'
,p_display_name=>'Recording Resumed'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125376985788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplussaved'
,p_display_name=>'Media Saved'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12124608562788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplusstart'
,p_display_name=>'Recording Started'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12124954065788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediaplusstop'
,p_display_name=>'Recording Stopped'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(12125055793788960)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_name=>'mediapluswarning'
,p_display_name=>'Size or Length Warning'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A204D65646961506C757320666F72204F7261636C652041504558202D206974656D20706C75672D696E2076322E302E302028617564696F2C20766964656F2C2070686F746F7329207C204D4954207C204861736861616D2053686F756B61';
wwv_flow_imp.g_varchar2_table(2) := '740A202A20436F6C6F75727320636F6D652066726F6D20556E6976657273616C205468656D65207661726961626C65732C20736F205468656D6520526F6C6C6572207374796C657320616E64206461726B206D6F6465206170706C792E0A202A2F0A2E6D';
wwv_flow_imp.g_varchar2_table(3) := '706C7573207B0A202020202D2D6D706C75732D62673A20766172282D2D75742D636F6D706F6E656E742D6261636B67726F756E642D636F6C6F722C2023666666293B0A202020202D2D6D706C75732D626F726465723A20766172282D2D75742D636F6D70';
wwv_flow_imp.g_varchar2_table(4) := '6F6E656E742D626F726465722D636F6C6F722C207267626128302C20302C20302C202E313229293B0A202020202D2D6D706C75732D746578743A20766172282D2D75742D636F6D706F6E656E742D746578742D64656661756C742D636F6C6F722C20696E';
wwv_flow_imp.g_varchar2_table(5) := '6865726974293B0A202020202D2D6D706C75732D6D757465643A20766172282D2D75742D636F6D706F6E656E742D746578742D6D757465642D636F6C6F722C207267626128302C20302C20302C202E3629293B0A202020202D2D6D706C75732D73756274';
wwv_flow_imp.g_varchar2_table(6) := '6C653A20766172282D2D75742D636F6D706F6E656E742D686967686C696768742D6261636B67726F756E642D636F6C6F722C207267626128302C20302C20302C202E30333529293B0A202020202D2D6D706C75732D616363656E743A20766172282D2D75';
wwv_flow_imp.g_varchar2_table(7) := '742D70616C657474652D7072696D6172792C2023303537326365293B0A202020202D2D6D706C75732D6F6E2D616363656E743A20766172282D2D75742D70616C657474652D7072696D6172792D636F6E74726173742C2023666666293B0A202020202D2D';
wwv_flow_imp.g_varchar2_table(8) := '6D706C75732D64616E6765723A20766172282D2D75742D70616C657474652D64616E6765722C2023636231313030293B0A202020202D2D6D706C75732D7761726E3A20766172282D2D75742D70616C657474652D7761726E696E672C2023666263653461';
wwv_flow_imp.g_varchar2_table(9) := '293B0A202020202D2D6D706C75732D737563636573733A20766172282D2D75742D70616C657474652D737563636573732C2023323738373031293B0A202020202D2D6D706C75732D7261646975733A20766172282D2D75742D636F6D706F6E656E742D62';
wwv_flow_imp.g_varchar2_table(10) := '6F726465722D7261646975732C20387078293B0A202020202D2D6D706C75732D776176653A20766172282D2D6D706C75732D64616E676572293B0A202020202D2D6D706C75732D776176652D69646C653A20766172282D2D6D706C75732D6D7574656429';
wwv_flow_imp.g_varchar2_table(11) := '3B0A20202020646973706C61793A20666C65783B0A20202020666C65782D646972656374696F6E3A20636F6C756D6E3B0A202020206761703A202E36323572656D3B0A2020202070616464696E673A202E373572656D3B0A20202020626F726465723A20';
wwv_flow_imp.g_varchar2_table(12) := '31707820736F6C696420766172282D2D6D706C75732D626F72646572293B0A20202020626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B0A202020206261636B67726F756E643A20766172282D2D6D706C75732D62';
wwv_flow_imp.g_varchar2_table(13) := '67293B0A20202020636F6C6F723A20766172282D2D6D706C75732D74657874293B0A202020206D696E2D77696474683A20303B0A2020202077696474683A20313030253B0A20202020626F782D73697A696E673A20626F726465722D626F783B0A7D0A2E';
wwv_flow_imp.g_varchar2_table(14) := '6D706C7573205B68696464656E5D207B20646973706C61793A206E6F6E652021696D706F7274616E743B207D0A2E6D706C75732D2D726F207B2070616464696E673A202E323572656D20303B20626F726465723A20303B206261636B67726F756E643A20';
wwv_flow_imp.g_varchar2_table(15) := '7472616E73706172656E743B207D0A2E6D706C75732D2D64697361626C6564202E6D706C75732D616374696F6E732C0A2E6D706C75732D2D64697361626C6564202E6D706C75732D736567207B206F7061636974793A202E35353B20706F696E7465722D';
wwv_flow_imp.g_varchar2_table(16) := '6576656E74733A206E6F6E653B207D0A0A2F2A20746F70206C696E65202A2F0A2E6D706C75732D746F70207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B206A7573746966792D636F6E74656E743A207370';
wwv_flow_imp.g_varchar2_table(17) := '6163652D6265747765656E3B206761703A202E3572656D3B20666C65782D777261703A20777261703B207D0A2E6D706C75732D736567207B20646973706C61793A20696E6C696E652D666C65783B20626F726465723A2031707820736F6C696420766172';
wwv_flow_imp.g_varchar2_table(18) := '282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A2039393970783B2070616464696E673A203270783B206761703A203270783B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B207D0A2E';
wwv_flow_imp.g_varchar2_table(19) := '6D706C75732D736567202E6D706C75732D62746E207B206865696768743A20312E373572656D3B20626F726465723A20303B206261636B67726F756E643A207472616E73706172656E743B20636F6C6F723A20766172282D2D6D706C75732D6D75746564';
wwv_flow_imp.g_varchar2_table(20) := '293B20626F782D736861646F773A206E6F6E653B207D0A2E6D706C75732D736567202E6D706C75732D62746E5B617269612D707265737365643D2274727565225D207B206261636B67726F756E643A20766172282D2D6D706C75732D616363656E74293B';
wwv_flow_imp.g_varchar2_table(21) := '20636F6C6F723A20766172282D2D6D706C75732D6F6E2D616363656E74293B206F7061636974793A20313B207D0A2E6D706C75732D6C616E67207B206865696768743A20312E373572656D3B2070616464696E673A2030202E3572656D3B20626F726465';
wwv_flow_imp.g_varchar2_table(22) := '723A2031707820736F6C696420766172282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A2039393970783B206261636B67726F756E643A20766172282D2D6D706C75732D6267293B20636F6C6F723A20766172282D2D6D70';
wwv_flow_imp.g_varchar2_table(23) := '6C75732D74657874293B20666F6E743A20696E68657269743B20666F6E742D73697A653A202E3831323572656D3B206D61782D77696474683A20313272656D3B207D0A2E6D706C75732D737461747573207B20646973706C61793A20696E6C696E652D66';
wwv_flow_imp.g_varchar2_table(24) := '6C65783B20616C69676E2D6974656D733A2063656E7465723B206761703A202E33373572656D3B206D617267696E2D696E6C696E652D73746172743A206175746F3B2070616464696E673A202E31323572656D202E36323572656D3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(25) := '2020202020202020626F726465722D7261646975733A2039393970783B20666F6E742D73697A653A202E373572656D3B20666F6E742D7765696768743A203630303B206C696E652D6865696768743A20312E3572656D3B206261636B67726F756E643A20';
wwv_flow_imp.g_varchar2_table(26) := '766172282D2D6D706C75732D737562746C65293B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B207D0A2E6D706C75732D7374617475732D2D7265636F7264696E67207B206261636B67726F756E643A20636F6C6F722D6D69782869';
wwv_flow_imp.g_varchar2_table(27) := '6E20737267622C20766172282D2D6D706C75732D64616E67657229203134252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D6D706C75732D64616E676572293B207D0A2E6D706C75732D7374617475732D2D7265636F7264696E';
wwv_flow_imp.g_varchar2_table(28) := '673A3A6265666F7265207B20636F6E74656E743A2022223B2077696474683A202E3572656D3B206865696768743A202E3572656D3B20626F726465722D7261646975733A203530253B206261636B67726F756E643A2063757272656E74436F6C6F723B20';
wwv_flow_imp.g_varchar2_table(29) := '616E696D6174696F6E3A206D706C75732D70756C736520312E327320656173652D696E2D6F757420696E66696E6974653B207D0A2E6D706C75732D7374617475732D2D706175736564207B206261636B67726F756E643A20636F6C6F722D6D697828696E';
wwv_flow_imp.g_varchar2_table(30) := '20737267622C20766172282D2D6D706C75732D7761726E29203330252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D6D706C75732D74657874293B207D0A2E6D706C75732D7374617475732D2D75706C6F6164696E672C202E6D';
wwv_flow_imp.g_varchar2_table(31) := '706C75732D7374617475732D2D726576696577207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D616363656E7429203134252C207472616E73706172656E74293B20636F6C6F723A2076';
wwv_flow_imp.g_varchar2_table(32) := '6172282D2D6D706C75732D616363656E74293B207D0A0A2F2A207374616765202A2F0A2E6D706C75732D7374616765207B20706F736974696F6E3A2072656C61746976653B206F766572666C6F773A2068696464656E3B20626F726465722D7261646975';
wwv_flow_imp.g_varchar2_table(33) := '733A20766172282D2D6D706C75732D726164697573293B207D0A2E6D706C75732D2D766964656F202E6D706C75732D7374616765207B206261636B67726F756E643A20233030303B206173706563742D726174696F3A203136202F20393B206D61782D68';
wwv_flow_imp.g_varchar2_table(34) := '65696768743A20363076683B2077696474683A20313030253B206D617267696E2D696E6C696E653A206175746F3B207D0A2E6D706C75732D2D766964656F202E6D706C75732D6C697665207B20646973706C61793A20626C6F636B3B2077696474683A20';
wwv_flow_imp.g_varchar2_table(35) := '313030253B206865696768743A20313030253B206F626A6563742D6669743A20636F6E7461696E3B206261636B67726F756E643A20233030303B207D0A2E6D706C75732D2D6D6972726F72202E6D706C75732D6C697665207B207472616E73666F726D3A';
wwv_flow_imp.g_varchar2_table(36) := '207363616C6558282D31293B207D0A2E6D706C75732D2D617564696F202E6D706C75732D7374616765207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B206761703A202E373572656D3B206865696768743A';
wwv_flow_imp.g_varchar2_table(37) := '203572656D3B2070616464696E673A2030202E38373572656D3B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D7374';
wwv_flow_imp.g_varchar2_table(38) := '616765207B206865696768743A203372656D3B207D0A2E6D706C75732D77617665207B20666C65783A20312031206175746F3B206D696E2D77696474683A20303B206865696768743A203730253B20646973706C61793A20626C6F636B3B207D0A5B6469';
wwv_flow_imp.g_varchar2_table(39) := '723D2272746C225D202E6D706C75732D77617665207B207472616E73666F726D3A207363616C6558282D31293B207D0A2E6D706C75732D6F7665726C6179207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B';
wwv_flow_imp.g_varchar2_table(40) := '206761703A202E3572656D3B207D0A2E6D706C75732D2D617564696F202E6D706C75732D6F7665726C6179207B206F726465723A202D313B20666C65783A20302030206175746F3B207D0A2E6D706C75732D2D766964656F202E6D706C75732D6F766572';
wwv_flow_imp.g_varchar2_table(41) := '6C6179207B20706F736974696F6E3A206162736F6C7574653B20696E7365742D696E6C696E653A202E36323572656D3B20746F703A202E36323572656D3B206A7573746966792D636F6E74656E743A2073706163652D6265747765656E3B20706F696E74';
wwv_flow_imp.g_varchar2_table(42) := '65722D6576656E74733A206E6F6E653B207D0A2E6D706C75732D726563207B20646973706C61793A20696E6C696E652D666C65783B20616C69676E2D6974656D733A2063656E7465723B206761703A202E3472656D3B20666F6E742D76617269616E742D';
wwv_flow_imp.g_varchar2_table(43) := '6E756D657269633A20746162756C61722D6E756D733B20666F6E742D7765696768743A203630303B207D0A2E6D706C75732D2D617564696F202E6D706C75732D726563207B20666F6E742D73697A653A20312E3572656D3B207D0A2E6D706C75732D2D63';
wwv_flow_imp.g_varchar2_table(44) := '6F6D706163742E6D706C75732D2D617564696F202E6D706C75732D726563207B20666F6E742D73697A653A20312E31323572656D3B207D0A2E6D706C75732D2D766964656F202E6D706C75732D726563207B2070616464696E673A202E31323572656D20';
wwv_flow_imp.g_varchar2_table(45) := '2E3572656D3B20626F726465722D7261646975733A2039393970783B206261636B67726F756E643A207267626128302C20302C20302C202E3535293B20636F6C6F723A20236666663B20666F6E742D73697A653A202E38373572656D3B207D0A2E6D706C';
wwv_flow_imp.g_varchar2_table(46) := '75732D646F74207B2077696474683A202E36323572656D3B206865696768743A202E36323572656D3B20626F726465722D7261646975733A203530253B206261636B67726F756E643A20766172282D2D6D706C75732D6D75746564293B207D0A2E6D706C';
wwv_flow_imp.g_varchar2_table(47) := '75735B646174612D73746174653D227265636F7264696E67225D202E6D706C75732D646F74207B206261636B67726F756E643A20766172282D2D6D706C75732D64616E676572293B20616E696D6174696F6E3A206D706C75732D70756C736520312E3273';
wwv_flow_imp.g_varchar2_table(48) := '20656173652D696E2D6F757420696E66696E6974653B207D0A2E6D706C75735B646174612D73746174653D22706175736564225D202E6D706C75732D646F74207B206261636B67726F756E643A20766172282D2D6D706C75732D7761726E293B207D0A2E';
wwv_flow_imp.g_varchar2_table(49) := '6D706C75732D2D766964656F202E6D706C75732D646F74207B206261636B67726F756E643A2072676261283235352C203235352C203235352C202E37293B207D0A2E6D706C75732D2D766964656F5B646174612D73746174653D227265636F7264696E67';
wwv_flow_imp.g_varchar2_table(50) := '225D202E6D706C75732D646F74207B206261636B67726F756E643A20236666336233303B207D0A2E6D706C75732D6C6576656C207B2077696474683A20342E3572656D3B206865696768743A202E33373572656D3B20626F726465722D7261646975733A';
wwv_flow_imp.g_varchar2_table(51) := '2039393970783B206261636B67726F756E643A2072676261283235352C203235352C203235352C202E33293B206F766572666C6F773A2068696464656E3B207D0A2E6D706C75732D6C6576656C203E207370616E207B20646973706C61793A20626C6F63';
wwv_flow_imp.g_varchar2_table(52) := '6B3B206865696768743A20313030253B2077696474683A20303B206261636B67726F756E643A20233334633735393B207472616E736974696F6E3A207769647468202E303873206C696E6561723B207D0A2E6D706C75732D636F756E74646F776E207B20';
wwv_flow_imp.g_varchar2_table(53) := '706F736974696F6E3A206162736F6C7574653B20696E7365743A20303B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B206A7573746966792D636F6E74656E743A2063656E7465723B20706F696E7465722D65';
wwv_flow_imp.g_varchar2_table(54) := '76656E74733A206E6F6E653B0A202020202020202020202020202020202020666F6E742D73697A653A203472656D3B20666F6E742D7765696768743A203730303B20636F6C6F723A20236666663B20746578742D736861646F773A203020327078203132';
wwv_flow_imp.g_varchar2_table(55) := '7078207267626128302C20302C20302C202E36293B207D0A2E6D706C75732D2D617564696F202E6D706C75732D636F756E74646F776E207B20636F6C6F723A20766172282D2D6D706C75732D616363656E74293B20666F6E742D73697A653A20322E3572';
wwv_flow_imp.g_varchar2_table(56) := '656D3B20746578742D736861646F773A206E6F6E653B207D0A2E6D706C75732D636F756E74646F776E3A656D707479207B20646973706C61793A206E6F6E653B207D0A0A2F2A2073697A65202F206C656E677468206D65746572202A2F0A2E6D706C7573';
wwv_flow_imp.g_varchar2_table(57) := '2D6D65746572207B20646973706C61793A20666C65783B20666C65782D646972656374696F6E3A20636F6C756D6E3B206761703A202E323572656D3B207D0A2E6D706C75732D6D657465722D747261636B207B20646973706C61793A20626C6F636B3B20';
wwv_flow_imp.g_varchar2_table(58) := '6865696768743A202E33373572656D3B20626F726465722D7261646975733A2039393970783B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B206F766572666C6F773A2068696464656E3B20626F782D736861646F77';
wwv_flow_imp.g_varchar2_table(59) := '3A20696E7365742030203020302031707820766172282D2D6D706C75732D626F72646572293B207D0A2E6D706C75732D6D657465722D66696C6C207B20646973706C61793A20626C6F636B3B206865696768743A20313030253B2077696474683A20303B';
wwv_flow_imp.g_varchar2_table(60) := '206261636B67726F756E643A20766172282D2D6D706C75732D616363656E74293B207472616E736974696F6E3A207769647468202E32357320656173652C206261636B67726F756E642D636F6C6F72202E32357320656173653B207D0A2E6D706C75732D';
wwv_flow_imp.g_varchar2_table(61) := '6D657465722E69732D7761726E202E6D706C75732D6D657465722D66696C6C207B206261636B67726F756E643A20766172282D2D6D706C75732D64616E676572293B207D0A2E6D706C75732D6D657465722D74657874207B20666F6E742D73697A653A20';
wwv_flow_imp.g_varchar2_table(62) := '2E373572656D3B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B20666F6E742D76617269616E742D6E756D657269633A20746162756C61722D6E756D733B207D0A2E6D706C75732D6D657465722E69732D7761726E202E6D706C7573';
wwv_flow_imp.g_varchar2_table(63) := '2D6D657465722D74657874207B20636F6C6F723A20766172282D2D6D706C75732D64616E676572293B20666F6E742D7765696768743A203630303B207D0A0A2F2A206E6F7469636573202A2F0A2E6D706C75732D6E6F74696365207B20646973706C6179';
wwv_flow_imp.g_varchar2_table(64) := '3A20666C65783B20616C69676E2D6974656D733A20666C65782D73746172743B206761703A202E3572656D3B2070616464696E673A202E3572656D202E373572656D3B20626F726465722D7261646975733A20766172282D2D6D706C75732D7261646975';
wwv_flow_imp.g_varchar2_table(65) := '73293B20666F6E742D73697A653A202E3831323572656D3B206C696E652D6865696768743A20312E343B0A2020202020202020202020202020206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C7573';
wwv_flow_imp.g_varchar2_table(66) := '2D616363656E7429203130252C207472616E73706172656E74293B207D0A2E6D706C75732D6E6F746963653A656D707479207B20646973706C61793A206E6F6E653B207D0A2E6D706C75732D6E6F74696365202E742D49636F6E207B206D617267696E2D';
wwv_flow_imp.g_varchar2_table(67) := '746F703A202E31323572656D3B207D0A2E6D706C75732D6E6F746963652D2D7761726E207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D7761726E29203234252C207472616E73706172';
wwv_flow_imp.g_varchar2_table(68) := '656E74293B20636F6C6F723A20766172282D2D6D706C75732D74657874293B207D0A2E6D706C75732D6E6F746963652D2D7761726E202E742D49636F6E207B20636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75';
wwv_flow_imp.g_varchar2_table(69) := '732D7761726E29203635252C2023303030293B207D0A2E6D706C75732D6E6F746963652D2D6572726F72207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D64616E67657229203132252C';
wwv_flow_imp.g_varchar2_table(70) := '207472616E73706172656E74293B20636F6C6F723A20766172282D2D6D706C75732D64616E676572293B207D0A0A2F2A207265636F7264657220636F6E74726F6C733A2070696C6C73207769746820647261776E2069636F6E73202A2F0A2E6D706C7573';
wwv_flow_imp.g_varchar2_table(71) := '2D616374696F6E73207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B20666C65782D777261703A20777261703B206761703A202E3572656D3B207D0A2E6D706C75732D62746E207B20646973706C61793A20';
wwv_flow_imp.g_varchar2_table(72) := '696E6C696E652D666C65783B20616C69676E2D6974656D733A2063656E7465723B206A7573746966792D636F6E74656E743A2063656E7465723B206761703A202E33373572656D3B206865696768743A203272656D3B206D617267696E3A20303B207061';
wwv_flow_imp.g_varchar2_table(73) := '6464696E673A2030202E38373572656D2030202E36323572656D3B0A202020202020202020202020626F726465723A2031707820736F6C696420766172282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A2039393970783B';
wwv_flow_imp.g_varchar2_table(74) := '206261636B67726F756E643A20766172282D2D6D706C75732D6267293B20636F6C6F723A20766172282D2D6D706C75732D74657874293B0A202020202020202020202020666F6E743A20696E68657269743B20666F6E742D73697A653A202E3831323572';
wwv_flow_imp.g_varchar2_table(75) := '656D3B20666F6E742D7765696768743A203630303B206C696E652D6865696768743A20313B2077686974652D73706163653A206E6F777261703B20746578742D6465636F726174696F6E3A206E6F6E653B20637572736F723A20706F696E7465723B0A20';
wwv_flow_imp.g_varchar2_table(76) := '2020202020202020202020626F782D736861646F773A20302031707820327078207267626128302C20302C20302C202E3036293B207472616E736974696F6E3A206261636B67726F756E642D636F6C6F72202E31357320656173652C20626F726465722D';
wwv_flow_imp.g_varchar2_table(77) := '636F6C6F72202E31357320656173652C20626F782D736861646F77202E31357320656173652C207472616E73666F726D202E30387320656173653B207D0A2E6D706C75732D62746E3A686F766572207B206261636B67726F756E643A20766172282D2D6D';
wwv_flow_imp.g_varchar2_table(78) := '706C75732D737562746C65293B20746578742D6465636F726174696F6E3A206E6F6E653B20636F6C6F723A20766172282D2D6D706C75732D74657874293B207D0A2E6D706C75732D62746E3A616374697665207B207472616E73666F726D3A207363616C';
wwv_flow_imp.g_varchar2_table(79) := '65282E3937293B207D0A2E6D706C75732D62746E3A666F6375732D76697369626C65207B206F75746C696E653A2032707820736F6C696420766172282D2D6D706C75732D616363656E74293B206F75746C696E652D6F66667365743A203270783B207D0A';
wwv_flow_imp.g_varchar2_table(80) := '2E6D706C75732D62746E5B64697361626C65645D207B206F7061636974793A202E34353B20637572736F723A2064656661756C743B207472616E73666F726D3A206E6F6E653B207D0A2E6D706C75732D62746E2D2D7265632C202E6D706C75732D62746E';
wwv_flow_imp.g_varchar2_table(81) := '2D2D73746F70207B206261636B67726F756E643A20766172282D2D6D706C75732D64616E676572293B20626F726465722D636F6C6F723A20766172282D2D6D706C75732D64616E676572293B20636F6C6F723A20236666663B20626F782D736861646F77';
wwv_flow_imp.g_varchar2_table(82) := '3A20302032707820387078202D32707820636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D64616E67657229203630252C207472616E73706172656E74293B207D0A2E6D706C75732D62746E2D2D7265633A686F7665722C20';
wwv_flow_imp.g_varchar2_table(83) := '2E6D706C75732D62746E2D2D73746F703A686F766572207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D64616E67657229203836252C2023303030293B20636F6C6F723A20236666663B';
wwv_flow_imp.g_varchar2_table(84) := '207D0A2E6D706C75732D62746E2D2D7072696D617279207B206261636B67726F756E643A20766172282D2D6D706C75732D616363656E74293B20626F726465722D636F6C6F723A20766172282D2D6D706C75732D616363656E74293B20636F6C6F723A20';
wwv_flow_imp.g_varchar2_table(85) := '766172282D2D6D706C75732D6F6E2D616363656E74293B207D0A2E6D706C75732D62746E2D2D7072696D6172793A686F766572207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D616363';
wwv_flow_imp.g_varchar2_table(86) := '656E7429203836252C2023303030293B20636F6C6F723A20766172282D2D6D706C75732D6F6E2D616363656E74293B207D0A2E6D706C75732D62746E2D2D67686F7374207B20626F726465722D636F6C6F723A207472616E73706172656E743B20626163';
wwv_flow_imp.g_varchar2_table(87) := '6B67726F756E643A207472616E73706172656E743B20626F782D736861646F773A206E6F6E653B207D0A2E6D706C75732D62746E2D2D69636F6E207B2077696474683A203272656D3B2070616464696E673A20303B207D0A2E6D706C75732D62746E2D2D';
wwv_flow_imp.g_varchar2_table(88) := '69636F6E202E6D706C75732D62746E2D6C6162656C207B20706F736974696F6E3A206162736F6C7574653B2077696474683A203170783B206865696768743A203170783B206F766572666C6F773A2068696464656E3B20636C69703A2072656374283020';
wwv_flow_imp.g_varchar2_table(89) := '3020302030293B2077686974652D73706163653A206E6F777261703B207D0A2E6D706C75732D69207B20706F736974696F6E3A2072656C61746976653B20646973706C61793A20696E6C696E652D626C6F636B3B20666C65783A206E6F6E653B20776964';
wwv_flow_imp.g_varchar2_table(90) := '74683A202E38373572656D3B206865696768743A202E38373572656D3B20666F6E742D73697A653A202E38373572656D3B206C696E652D6865696768743A202E38373572656D3B20746578742D616C69676E3A2063656E7465723B207D0A2E6D706C7573';
wwv_flow_imp.g_varchar2_table(91) := '2D692D2D7265633A3A6265666F7265207B20636F6E74656E743A2022223B20706F736974696F6E3A206162736F6C7574653B20696E7365743A202E31323572656D3B20626F726465722D7261646975733A203530253B206261636B67726F756E643A2063';
wwv_flow_imp.g_varchar2_table(92) := '757272656E74436F6C6F723B207D0A2E6D706C75732D692D2D73746F703A3A6265666F7265207B20636F6E74656E743A2022223B20706F736974696F6E3A206162736F6C7574653B20696E7365743A202E3138373572656D3B20626F726465722D726164';
wwv_flow_imp.g_varchar2_table(93) := '6975733A203270783B206261636B67726F756E643A2063757272656E74436F6C6F723B207D0A2E6D706C75732D692D2D70617573653A3A6265666F72652C202E6D706C75732D692D2D70617573653A3A6166746572207B20636F6E74656E743A2022223B';
wwv_flow_imp.g_varchar2_table(94) := '20706F736974696F6E3A206162736F6C7574653B20746F703A202E31323572656D3B20626F74746F6D3A202E31323572656D3B2077696474683A203370783B20626F726465722D7261646975733A203170783B206261636B67726F756E643A2063757272';
wwv_flow_imp.g_varchar2_table(95) := '656E74436F6C6F723B207D0A2E6D706C75732D692D2D70617573653A3A6265666F7265207B206C6566743A203270783B207D0A2E6D706C75732D692D2D70617573653A3A6166746572207B2072696768743A203270783B207D0A2E6D706C75732D692D2D';
wwv_flow_imp.g_varchar2_table(96) := '706C61793A3A6265666F7265207B20636F6E74656E743A2022223B20706F736974696F6E3A206162736F6C7574653B20696E7365743A202E31323572656D202E3036323572656D202E31323572656D202E323572656D3B206261636B67726F756E643A20';
wwv_flow_imp.g_varchar2_table(97) := '63757272656E74436F6C6F723B20636C69702D706174683A20706F6C79676F6E283020302C2031303025203530252C20302031303025293B207D0A5B6469723D2272746C225D202E6D706C75732D692D2D706C61793A3A6265666F7265207B207472616E';
wwv_flow_imp.g_varchar2_table(98) := '73666F726D3A207363616C6558282D31293B207D0A2E6D706C75732D622D636C6F7365207B206D617267696E2D696E6C696E652D73746172743A206175746F3B207D0A2E6D706C75732D62746E2D2D7468656D65207B206D617267696E3A20303B207D0A';
wwv_flow_imp.g_varchar2_table(99) := '2E6D706C75732D62746E2D2D7468656D65202E6D706C75732D69207B206D617267696E2D696E6C696E652D656E643A202E33373572656D3B207D0A2E6D706C75732D62746E2D2D7468656D652E742D427574746F6E2D2D6E6F4C6162656C202E6D706C75';
wwv_flow_imp.g_varchar2_table(100) := '732D69207B206D617267696E3A20303B207D0A2E6D706C75732D62746E2D2D7468656D65202E6D706C75732D62746E2D6C6162656C3A656D707479207B20646973706C61793A206E6F6E653B207D0A0A2F2A20436F6D706163743A206F6E65206C696E65';
wwv_flow_imp.g_varchar2_table(101) := '207768696C65207265636F7264696E67202D205B646F7420303A30392077617665666F726D5D205B70617573655D205B73746F705D2C20746865206D657465722061732061207468696E206C696E652062656C6F77202A2F0A2E6D706C75732D2D636F6D';
wwv_flow_imp.g_varchar2_table(102) := '706163742E6D706C75732D2D617564696F207B20646973706C61793A20677269643B20677269642D74656D706C6174652D636F6C756D6E733A206D696E6D617828302C2031667229206175746F3B20636F6C756D6E2D6761703A202E3572656D3B20726F';
wwv_flow_imp.g_varchar2_table(103) := '772D6761703A20303B20616C69676E2D6974656D733A2063656E7465723B0A2020202020202020202020202020202020202020202020202020202020677269642D74656D706C6174652D61726561733A2022746F7020746F702220227374616765206163';
wwv_flow_imp.g_varchar2_table(104) := '74696F6E73222022737474207374742220226D65746572206D657465722220226E6F74696365206E6F746963652220227265766965772072657669657722202268696E742068696E742220226C697374206C697374223B207D0A2E6D706C75732D2D636F';
wwv_flow_imp.g_varchar2_table(105) := '6D706163742E6D706C75732D2D617564696F203E202E6D706C75732D746F70207B20677269642D617265613A20746F703B206D617267696E2D626F74746F6D3A202E3572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564';
wwv_flow_imp.g_varchar2_table(106) := '696F203E202E6D706C75732D7374616765207B20677269642D617265613A2073746167653B206865696768743A20322E3572656D3B2070616464696E673A2030202E36323572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D61';
wwv_flow_imp.g_varchar2_table(107) := '7564696F203E202E6D706C75732D616374696F6E732D2D6D61696E207B20677269642D617265613A20616374696F6E733B20666C65782D777261703A206E6F777261703B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F20';
wwv_flow_imp.g_varchar2_table(108) := '3E202E6D706C75732D737474207B20677269642D617265613A207374743B206D617267696E2D746F703A202E3572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F203E202E6D706C75732D6D65746572207B206772';
wwv_flow_imp.g_varchar2_table(109) := '69642D617265613A206D657465723B206D617267696E2D746F703A202E33373572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F203E202E6D706C75732D6E6F74696365207B20677269642D617265613A206E6F74';
wwv_flow_imp.g_varchar2_table(110) := '6963653B206D617267696E2D746F703A202E3572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F203E202E6D706C75732D726576696577207B20677269642D617265613A207265766965773B207D0A2E6D706C7573';
wwv_flow_imp.g_varchar2_table(111) := '2D2D636F6D706163742E6D706C75732D2D617564696F203E202E6D706C75732D68696E74207B20677269642D617265613A2068696E743B206D617267696E2D746F703A202E33373572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C7573';
wwv_flow_imp.g_varchar2_table(112) := '2D2D617564696F203E202E6D706C75732D6C697374207B20677269642D617265613A206C6973743B206D617267696E2D746F703A202E36323572656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F5B646174612D7374';
wwv_flow_imp.g_varchar2_table(113) := '6174653D2269646C65225D203E202E6D706C75732D616374696F6E732D2D6D61696E207B20677269642D617265613A206175746F3B20677269642D636F6C756D6E3A2031202F202D313B20677269642D726F773A20323B20666C65782D777261703A2077';
wwv_flow_imp.g_varchar2_table(114) := '7261703B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D7374616765202E6D706C75732D726563207B20666F6E742D73697A653A203172656D3B207D0A2E6D706C75732D2D636F6D706163742E6D706C';
wwv_flow_imp.g_varchar2_table(115) := '75732D2D617564696F202E6D706C75732D622D70617573652C202E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D73746F70207B2077696474683A203272656D3B2070616464696E673A20303B207D0A2E6D';
wwv_flow_imp.g_varchar2_table(116) := '706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D7061757365202E6D706C75732D62746E2D6C6162656C2C202E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D7374';
wwv_flow_imp.g_varchar2_table(117) := '6F70202E6D706C75732D62746E2D6C6162656C207B0A20202020706F736974696F6E3A206162736F6C7574653B2077696474683A203170783B206865696768743A203170783B206F766572666C6F773A2068696464656E3B20636C69703A207265637428';
wwv_flow_imp.g_varchar2_table(118) := '30203020302030293B2077686974652D73706163653A206E6F777261703B207D0A2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D6D65746572207B206761703A202E31323572656D3B207D0A2E6D706C75732D';
wwv_flow_imp.g_varchar2_table(119) := '2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D6D657465722D747261636B207B206865696768743A202E323572656D3B207D0A2E6D706C75732D66696C65207B20646973706C61793A206E6F6E653B207D0A2E6D706C75732D68';
wwv_flow_imp.g_varchar2_table(120) := '696E74207B20666F6E742D73697A653A202E373572656D3B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B207D0A0A2F2A20726576696577202A2F0A2E6D706C75732D726576696577207B20646973706C61793A20666C65783B2066';
wwv_flow_imp.g_varchar2_table(121) := '6C65782D646972656374696F6E3A20636F6C756D6E3B206761703A202E3572656D3B2070616464696E673A202E373572656D3B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(122) := '202020626F726465723A203170782064617368656420636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D616363656E7429203535252C207472616E73706172656E74293B206261636B67726F756E643A20636F6C6F722D6D69';
wwv_flow_imp.g_varchar2_table(123) := '7828696E20737267622C20766172282D2D6D706C75732D616363656E74292035252C207472616E73706172656E74293B207D0A2E6D706C75732D7265766965772D7469746C65207B20666F6E742D73697A653A202E3831323572656D3B20666F6E742D77';
wwv_flow_imp.g_varchar2_table(124) := '65696768743A203630303B207D0A2E6D706C75732D7265766965772D6D657461207B20666F6E742D73697A653A202E373572656D3B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B20666F6E742D76617269616E742D6E756D657269';
wwv_flow_imp.g_varchar2_table(125) := '633A20746162756C61722D6E756D733B207D0A2E6D706C75732D6D65646961207B20646973706C61793A20626C6F636B3B2077696474683A20313030253B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B207D';
wwv_flow_imp.g_varchar2_table(126) := '0A766964656F2E6D706C75732D6D65646961207B206261636B67726F756E643A20233030303B206D61782D6865696768743A20353576683B207D0A617564696F2E6D706C75732D6D65646961207B206865696768743A20322E3572656D3B207D0A0A2F2A';
wwv_flow_imp.g_varchar2_table(127) := '206C697374202A2F0A2E6D706C75732D6C697374207B206C6973742D7374796C653A206E6F6E653B206D617267696E3A20303B2070616464696E673A20303B20646973706C61793A20666C65783B20666C65782D646972656374696F6E3A20636F6C756D';
wwv_flow_imp.g_varchar2_table(128) := '6E3B206761703A202E33373572656D3B207D0A2E6D706C75732D726F77207B20646973706C61793A20677269643B20677269642D74656D706C6174652D636F6C756D6E733A206175746F206D696E6D617828302C2031667229206175746F3B20616C6967';
wwv_flow_imp.g_varchar2_table(129) := '6E2D6974656D733A2063656E7465723B206761703A202E323572656D202E36323572656D3B0A20202020202020202020202070616464696E673A202E3572656D202E3572656D202E3572656D202E36323572656D3B20626F726465723A2031707820736F';
wwv_flow_imp.g_varchar2_table(130) := '6C696420766172282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B206261636B67726F756E643A20766172282D2D6D706C75732D6267293B207D0A2E6D706C75732D2D';
wwv_flow_imp.g_varchar2_table(131) := '726F202E6D706C75732D726F77207B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B207D0A2E6D706C75732D726F772D69636F207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E74';
wwv_flow_imp.g_varchar2_table(132) := '65723B206A7573746966792D636F6E74656E743A2063656E7465723B2077696474683A20322E323572656D3B206865696768743A20322E323572656D3B20626F726465722D7261646975733A203530253B0A202020202020202020202020202020206261';
wwv_flow_imp.g_varchar2_table(133) := '636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D616363656E7429203132252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D6D706C75732D616363656E74293B207D0A2E6D';
wwv_flow_imp.g_varchar2_table(134) := '706C75732D726F772D69636F202E6661207B20646973706C61793A20626C6F636B3B20666F6E742D73697A653A203172656D3B206C696E652D6865696768743A20313B2077696474683A206175746F3B206865696768743A206175746F3B207D0A2E6D70';
wwv_flow_imp.g_varchar2_table(135) := '6C75732D726F772D74657874207B20677269642D636F6C756D6E3A2032202F202D313B20666F6E742D73697A653A202E3831323572656D3B206C696E652D6865696768743A20312E34353B20636F6C6F723A20766172282D2D6D706C75732D7465787429';
wwv_flow_imp.g_varchar2_table(136) := '3B2077686974652D73706163653A207072652D777261703B0A2020202020202020202020202020202020646973706C61793A202D7765626B69742D626F783B202D7765626B69742D6C696E652D636C616D703A20333B202D7765626B69742D626F782D6F';
wwv_flow_imp.g_varchar2_table(137) := '7269656E743A20766572746963616C3B206F766572666C6F773A2068696464656E3B207D0A0A2F2A207472616E736372697074696F6E202A2F0A2E6D706C75732D737474207B2070616464696E673A202E3572656D202E373572656D3B20626F72646572';
wwv_flow_imp.g_varchar2_table(138) := '2D7261646975733A20766172282D2D6D706C75732D726164697573293B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B20666F6E742D73697A653A202E38373572656D3B206C696E652D6865696768743A20312E353B';
wwv_flow_imp.g_varchar2_table(139) := '206D61782D6865696768743A20372E3572656D3B206F766572666C6F772D793A206175746F3B207D0A2E6D706C75732D7374742D696E746572696D207B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B20666F6E742D7374796C653A';
wwv_flow_imp.g_varchar2_table(140) := '206974616C69633B207D0A2E6D706C75732D7472616E7363726970742D626F78207B20646973706C61793A20666C65783B20666C65782D646972656374696F6E3A20636F6C756D6E3B206761703A202E323572656D3B207D0A2E6D706C75732D7472616E';
wwv_flow_imp.g_varchar2_table(141) := '7363726970742D6C6162656C207B20666F6E742D73697A653A202E373572656D3B20666F6E742D7765696768743A203630303B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B207D0A2E6D706C75732D7472616E736372697074207B';
wwv_flow_imp.g_varchar2_table(142) := '2077696474683A20313030253B20626F782D73697A696E673A20626F726465722D626F783B206D696E2D6865696768743A20342E3572656D3B20726573697A653A20766572746963616C3B2070616464696E673A202E3572656D202E36323572656D3B20';
wwv_flow_imp.g_varchar2_table(143) := '666F6E743A20696E68657269743B20666F6E742D73697A653A202E38373572656D3B206C696E652D6865696768743A20312E34353B0A20202020202020202020202020202020202020626F726465723A2031707820736F6C696420766172282D2D6D706C';
wwv_flow_imp.g_varchar2_table(144) := '75732D626F72646572293B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B206261636B67726F756E643A20766172282D2D6D706C75732D6267293B20636F6C6F723A20766172282D2D6D706C75732D74657874';
wwv_flow_imp.g_varchar2_table(145) := '293B207D0A2E6D706C75732D7472616E7363726970743A666F637573207B206F75746C696E653A2032707820736F6C696420766172282D2D6D706C75732D616363656E74293B206F75746C696E652D6F66667365743A202D3170783B207D0A2E6D706C75';
wwv_flow_imp.g_varchar2_table(146) := '732D726F772D6D61696E207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B20666C65782D777261703A20777261703B206761703A202E31323572656D202E3572656D3B206D696E2D77696474683A20303B20';
wwv_flow_imp.g_varchar2_table(147) := '7D0A2E6D706C75732D726F772D6E616D65207B20666C65783A2031203120313030253B206D696E2D77696474683A20303B20666F6E742D73697A653A202E3831323572656D3B20666F6E742D7765696768743A203630303B206F766572666C6F773A2068';
wwv_flow_imp.g_varchar2_table(148) := '696464656E3B20746578742D6F766572666C6F773A20656C6C69707369733B2077686974652D73706163653A206E6F777261703B207D0A2E6D706C75732D726F772D6D657461207B20666F6E742D73697A653A202E373572656D3B20636F6C6F723A2076';
wwv_flow_imp.g_varchar2_table(149) := '6172282D2D6D706C75732D6D75746564293B20666F6E742D76617269616E742D6E756D657269633A20746162756C61722D6E756D733B207D0A2E6D706C75732D746167207B20666F6E742D73697A653A202E3638373572656D3B206C696E652D68656967';
wwv_flow_imp.g_varchar2_table(150) := '68743A20312E3172656D3B2070616464696E673A2030202E3472656D3B20626F726465722D7261646975733A2039393970783B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B20636F6C6F723A20766172282D2D6D70';
wwv_flow_imp.g_varchar2_table(151) := '6C75732D6D75746564293B207D0A2E6D706C75732D7461672D2D7361766564207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D7375636365737329203134252C207472616E7370617265';
wwv_flow_imp.g_varchar2_table(152) := '6E74293B20636F6C6F723A20766172282D2D6D706C75732D73756363657373293B207D0A2E6D706C75732D726F772D70726F6772657373207B20666C65783A2031203120313030253B206865696768743A202E323572656D3B20626F726465722D726164';
wwv_flow_imp.g_varchar2_table(153) := '6975733A2039393970783B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B206F766572666C6F773A2068696464656E3B207D0A2E6D706C75732D726F772D70726F6772657373203E207370616E207B20646973706C61';
wwv_flow_imp.g_varchar2_table(154) := '793A20626C6F636B3B206865696768743A20313030253B2077696474683A20303B206261636B67726F756E643A20766172282D2D6D706C75732D616363656E74293B207472616E736974696F6E3A207769647468202E327320656173653B207D0A2E6D70';
wwv_flow_imp.g_varchar2_table(155) := '6C75732D726F772D62746E73207B20646973706C61793A20696E6C696E652D666C65783B20616C69676E2D6974656D733A2063656E7465723B206761703A202E31323572656D3B207D0A2E6D706C75732D726F772D62746E73202E742D427574746F6E20';
wwv_flow_imp.g_varchar2_table(156) := '7B206D617267696E3A20303B207D0A2E6D706C75732D722D64656C3A686F766572202E742D49636F6E207B20636F6C6F723A20766172282D2D6D706C75732D64616E676572293B207D0A2E6D706C75732D726F772D706C61796572207B20677269642D63';
wwv_flow_imp.g_varchar2_table(157) := '6F6C756D6E3A2031202F202D313B2070616464696E672D746F703A202E323572656D3B207D0A0A2F2A2070686F746F733A20736875747465722C20666C6173682C206C697374207468756D626E61696C732C20766965776572202A2F0A2E6D706C75732D';
wwv_flow_imp.g_varchar2_table(158) := '62746E2D2D73687574746572207B206261636B67726F756E643A20766172282D2D6D706C75732D616363656E74293B20626F726465722D636F6C6F723A20766172282D2D6D706C75732D616363656E74293B20636F6C6F723A20766172282D2D6D706C75';
wwv_flow_imp.g_varchar2_table(159) := '732D6F6E2D616363656E74293B207D0A2E6D706C75732D62746E2D2D736875747465723A686F766572207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D6D706C75732D616363656E7429203836252C20';
wwv_flow_imp.g_varchar2_table(160) := '23303030293B20636F6C6F723A20766172282D2D6D706C75732D6F6E2D616363656E74293B207D0A2E6D706C75732D2D696D616765202E6D706C75732D7374616765207B206173706563742D726174696F3A2034202F20333B207D0A2E6D706C75732D73';
wwv_flow_imp.g_varchar2_table(161) := '746167652E69732D666C6173683A3A6166746572207B20636F6E74656E743A2022223B20706F736974696F6E3A206162736F6C7574653B20696E7365743A20303B206261636B67726F756E643A20236666663B20616E696D6174696F6E3A206D706C7573';
wwv_flow_imp.g_varchar2_table(162) := '2D666C617368202E327320656173652D6F757420666F7277617264733B20706F696E7465722D6576656E74733A206E6F6E653B207D0A2E6D706C75732D726F772D69636F207B206F766572666C6F773A2068696464656E3B207D0A2E6D706C75732D726F';
wwv_flow_imp.g_varchar2_table(163) := '772D2D696D616765202E6D706C75732D726F772D69636F207B20626F726465722D7261646975733A203670783B207D0A2E6D706C75732D726F772D7468756D62207B20646973706C61793A20626C6F636B3B2077696474683A20313030253B2068656967';
wwv_flow_imp.g_varchar2_table(164) := '68743A20313030253B206F626A6563742D6669743A20636F7665723B207D0A2E6D706C75732D70686F746F207B20646973706C61793A20626C6F636B3B206D61782D77696474683A20313030253B206D61782D6865696768743A20363076683B206D6172';
wwv_flow_imp.g_varchar2_table(165) := '67696E3A2030206175746F3B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B207D0A0A2F2A2070686F746F20656469746F72';
wwv_flow_imp.g_varchar2_table(166) := '202A2F0A2E6D706C75732D6564207B20646973706C61793A20666C65783B20666C65782D646972656374696F6E3A20636F6C756D6E3B206761703A202E3572656D3B207D0A2E6D706C75732D65642D7374616765207B20646973706C61793A20666C6578';
wwv_flow_imp.g_varchar2_table(167) := '3B206A7573746966792D636F6E74656E743A2063656E7465723B2070616464696E673A202E3572656D3B20626F726465722D7261646975733A20766172282D2D6D706C75732D726164697573293B0A202020202020202020202020202020202020626163';
wwv_flow_imp.g_varchar2_table(168) := '6B67726F756E643A20726570656174696E672D636F6E69632D6772616469656E7428766172282D2D6D706C75732D737562746C65292030203235252C207472616E73706172656E742030203530252920353025202F203136707820313670783B207D0A2E';
wwv_flow_imp.g_varchar2_table(169) := '6D706C75732D65642D77726170207B20706F736974696F6E3A2072656C61746976653B20646973706C61793A20696E6C696E652D626C6F636B3B206C696E652D6865696768743A20303B206D61782D77696474683A20313030253B20746F7563682D6163';
wwv_flow_imp.g_varchar2_table(170) := '74696F6E3A206E6F6E653B20757365722D73656C6563743A206E6F6E653B202D7765626B69742D757365722D73656C6563743A206E6F6E653B207D0A2E6D706C75732D65642D63616E766173207B20646973706C61793A20626C6F636B3B206D61782D77';
wwv_flow_imp.g_varchar2_table(171) := '696474683A20313030253B206D61782D6865696768743A20353576683B2077696474683A206175746F3B206865696768743A206175746F3B207D0A2E6D706C75732D65642E69732D64726177696E67202E6D706C75732D65642D63616E766173207B2063';
wwv_flow_imp.g_varchar2_table(172) := '7572736F723A2063726F7373686169723B207D0A2E6D706C75732D65642D63726F70207B20706F736974696F6E3A206162736F6C7574653B20626F782D73697A696E673A20626F726465722D626F783B20626F726465723A2032707820736F6C69642023';
wwv_flow_imp.g_varchar2_table(173) := '6666663B20626F782D736861646F773A20302030203020393939397078207267626128302C20302C20302C202E35292C20302030203020317078207267626128302C20302C20302C202E34293B0A2020202020202020202020202020202020637572736F';
wwv_flow_imp.g_varchar2_table(174) := '723A206D6F76653B20746F7563682D616374696F6E3A206E6F6E653B206F75746C696E653A206E6F6E653B0A20202020202020202020202020202020206261636B67726F756E642D696D6167653A206C696E6561722D6772616469656E74287267626128';
wwv_flow_imp.g_varchar2_table(175) := '3235352C3235352C3235352C2E3335292C2072676261283235352C3235352C3235352C2E333529292C206C696E6561722D6772616469656E742872676261283235352C3235352C3235352C2E3335292C2072676261283235352C3235352C3235352C2E33';
wwv_flow_imp.g_varchar2_table(176) := '3529292C0A20202020202020202020202020202020202020202020202020202020202020202020206C696E6561722D6772616469656E742872676261283235352C3235352C3235352C2E3335292C2072676261283235352C3235352C3235352C2E333529';
wwv_flow_imp.g_varchar2_table(177) := '292C206C696E6561722D6772616469656E742872676261283235352C3235352C3235352C2E3335292C2072676261283235352C3235352C3235352C2E333529293B0A20202020202020202020202020202020206261636B67726F756E642D73697A653A20';
wwv_flow_imp.g_varchar2_table(178) := '31707820313030252C2031707820313030252C2031303025203170782C2031303025203170783B206261636B67726F756E642D706F736974696F6E3A2033332E33332520302C2036362E36362520302C20302033332E3333252C20302036362E3636253B';
wwv_flow_imp.g_varchar2_table(179) := '206261636B67726F756E642D7265706561743A206E6F2D7265706561743B207D0A2E6D706C75732D65642D63726F703A666F6375732D76697369626C65207B20626F726465722D636F6C6F723A20766172282D2D6D706C75732D616363656E74293B207D';
wwv_flow_imp.g_varchar2_table(180) := '0A2E6D706C75732D65642D77726170207B206F766572666C6F773A2068696464656E3B207D0A2F2A2068616E646C657320736974206A75737420696E736964652074686520626F782C20736F207468657920737461792076697369626C65207768656E20';
wwv_flow_imp.g_varchar2_table(181) := '7468652063726F70206973207468652077686F6C652070686F746F202A2F0A2E6D706C75732D65642D68207B20706F736974696F6E3A206162736F6C7574653B2077696474683A20313670783B206865696768743A20313670783B206261636B67726F75';
wwv_flow_imp.g_varchar2_table(182) := '6E643A20236666663B20626F726465722D7261646975733A203370783B20626F782D736861646F773A20302031707820337078207267626128302C20302C20302C202E35293B207D0A2E6D706C75732D65642D682D2D6E77207B206C6566743A20327078';
wwv_flow_imp.g_varchar2_table(183) := '3B20746F703A203270783B20637572736F723A206E7773652D726573697A653B207D0A2E6D706C75732D65642D682D2D6E65207B2072696768743A203270783B20746F703A203270783B20637572736F723A206E6573772D726573697A653B207D0A2E6D';
wwv_flow_imp.g_varchar2_table(184) := '706C75732D65642D682D2D7365207B2072696768743A203270783B20626F74746F6D3A203270783B20637572736F723A206E7773652D726573697A653B207D0A2E6D706C75732D65642D682D2D7377207B206C6566743A203270783B20626F74746F6D3A';
wwv_flow_imp.g_varchar2_table(185) := '203270783B20637572736F723A206E6573772D726573697A653B207D0A2E6D706C75732D65642D682D2D6E2C202E6D706C75732D65642D682D2D73207B206C6566743A203530253B2077696474683A20323870783B206865696768743A203670783B206D';
wwv_flow_imp.g_varchar2_table(186) := '617267696E2D6C6566743A202D313470783B20637572736F723A206E732D726573697A653B207D0A2E6D706C75732D65642D682D2D6E207B20746F703A203270783B207D0A2E6D706C75732D65642D682D2D73207B20626F74746F6D3A203270783B207D';
wwv_flow_imp.g_varchar2_table(187) := '0A2E6D706C75732D65642D682D2D652C202E6D706C75732D65642D682D2D77207B20746F703A203530253B2077696474683A203670783B206865696768743A20323870783B206D617267696E2D746F703A202D313470783B20637572736F723A2065772D';
wwv_flow_imp.g_varchar2_table(188) := '726573697A653B207D0A2E6D706C75732D65642D682D2D65207B2072696768743A203270783B207D0A2E6D706C75732D65642D682D2D77207B206C6566743A203270783B207D0A406D656469612028706F696E7465723A20636F6172736529207B202E6D';
wwv_flow_imp.g_varchar2_table(189) := '706C75732D65642D682D2D6E772C202E6D706C75732D65642D682D2D6E652C202E6D706C75732D65642D682D2D73652C202E6D706C75732D65642D682D2D7377207B2077696474683A20323270783B206865696768743A20323270783B207D207D0A2E6D';
wwv_flow_imp.g_varchar2_table(190) := '706C75732D65642D746F6F6C73207B20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B20666C65782D777261703A20777261703B206761703A202E323572656D3B207D0A2E6D706C75732D65642D746F6F6C7320';
wwv_flow_imp.g_varchar2_table(191) := '2E6D706C75732D62746E5B617269612D707265737365643D2274727565225D2C202E6D706C75732D65642D746F6F6C73202E742D427574746F6E5B617269612D707265737365643D2274727565225D207B206261636B67726F756E643A20636F6C6F722D';
wwv_flow_imp.g_varchar2_table(192) := '6D697828696E20737267622C20766172282D2D6D706C75732D616363656E7429203136252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D6D706C75732D616363656E74293B207D0A2F2A20556E6976657273616C205468656D65';
wwv_flow_imp.g_varchar2_table(193) := '2067697665732073656C65637473206F726465723A2033202D2074686520746F6F6C626172206B6565707320697473206F776E206F726465722C205265736574206C617374202A2F0A2E6D706C7573202E6D706C75732D65642D73656C6563742C202E6D';
wwv_flow_imp.g_varchar2_table(194) := '706C7573202E6D706C75732D6C616E67207B206F726465723A20303B207D0A2E6D706C75732D65642D73656C656374207B206865696768743A203272656D3B2070616464696E673A2030202E3572656D3B20626F726465723A2031707820736F6C696420';
wwv_flow_imp.g_varchar2_table(195) := '766172282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A2039393970783B206261636B67726F756E643A20766172282D2D6D706C75732D6267293B20636F6C6F723A20766172282D2D6D706C75732D74657874293B20666F';
wwv_flow_imp.g_varchar2_table(196) := '6E743A20696E68657269743B20666F6E742D73697A653A202E3831323572656D3B207D0A2E6D706C7573202E6D706C75732D652D7265736574207B206F726465723A20313B206D617267696E2D696E6C696E652D73746172743A206175746F3B207D0A2E';
wwv_flow_imp.g_varchar2_table(197) := '6D706C75732D65642D636F6C6F757273207B20646973706C61793A20696E6C696E652D666C65783B206761703A202E323572656D3B2070616464696E673A2030202E323572656D3B207D0A2E6D706C75732D65642D636F6C6F7572207B2077696474683A';
wwv_flow_imp.g_varchar2_table(198) := '20312E3572656D3B206865696768743A20312E3572656D3B2070616464696E673A20303B20626F726465723A2032707820736F6C696420766172282D2D6D706C75732D626F72646572293B20626F726465722D7261646975733A203530253B2063757273';
wwv_flow_imp.g_varchar2_table(199) := '6F723A20706F696E7465723B207D0A2E6D706C75732D65642D636F6C6F75725B617269612D707265737365643D2274727565225D207B20626F726465722D636F6C6F723A20766172282D2D6D706C75732D616363656E74293B20626F782D736861646F77';
wwv_flow_imp.g_varchar2_table(200) := '3A2030203020302032707820766172282D2D6D706C75732D62672920696E7365743B207D0A2E6D706C75732D65642D61646A757374207B20646973706C61793A20677269643B20677269642D74656D706C6174652D636F6C756D6E733A20726570656174';
wwv_flow_imp.g_varchar2_table(201) := '286175746F2D6669742C206D696E6D617828313072656D2C2031667229293B206761703A202E3572656D203172656D3B2070616464696E673A202E3572656D202E373572656D3B20626F726465722D7261646975733A20766172282D2D6D706C75732D72';
wwv_flow_imp.g_varchar2_table(202) := '6164697573293B206261636B67726F756E643A20766172282D2D6D706C75732D737562746C65293B207D0A2E6D706C75732D65642D736C69646572207B20646973706C61793A20666C65783B20666C65782D646972656374696F6E3A20636F6C756D6E3B';
wwv_flow_imp.g_varchar2_table(203) := '206761703A202E31323572656D3B20666F6E742D73697A653A202E373572656D3B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B207D0A2E6D706C75732D65642D72616E6765207B2077696474683A20313030253B20616363656E74';
wwv_flow_imp.g_varchar2_table(204) := '2D636F6C6F723A20766172282D2D6D706C75732D616363656E74293B207D0A2E6D706C75732D65642D6D657461207B20666F6E742D73697A653A202E373572656D3B20636F6C6F723A20766172282D2D6D706C75732D6D75746564293B20666F6E742D76';
wwv_flow_imp.g_varchar2_table(205) := '617269616E742D6E756D657269633A20746162756C61722D6E756D733B207D0A0A406B65796672616D6573206D706C75732D666C617368207B2066726F6D207B206F7061636974793A202E393B207D20746F207B206F7061636974793A20303B207D207D';
wwv_flow_imp.g_varchar2_table(206) := '0A406B65796672616D6573206D706C75732D70756C7365207B2030252C2031303025207B206F7061636974793A20313B207D20353025207B206F7061636974793A202E33353B207D207D0A406D656469612028707265666572732D726564756365642D6D';
wwv_flow_imp.g_varchar2_table(207) := '6F74696F6E3A2072656475636529207B0A202020202E6D706C75732D7374617475732D2D7265636F7264696E673A3A6265666F72652C202E6D706C75735B646174612D73746174653D227265636F7264696E67225D202E6D706C75732D646F74207B2061';
wwv_flow_imp.g_varchar2_table(208) := '6E696D6174696F6E3A206E6F6E653B207D0A7D0A406D6564696120286D61782D77696474683A20343830707829207B0A202020202E6D706C7573207B2070616464696E673A202E36323572656D3B207D0A202020202E6D706C75732D616374696F6E7320';
wwv_flow_imp.g_varchar2_table(209) := '2E6D706C75732D62746E207B20666C65783A20312031206175746F3B206865696768743A20322E323572656D3B207D0A202020202E6D706C75732D616374696F6E73202E6D706C75732D62746E2D2D69636F6E2C202E6D706C75732D616374696F6E7320';
wwv_flow_imp.g_varchar2_table(210) := '2E6D706C75732D62746E2D2D67686F7374207B20666C65783A20302030206175746F3B207D0A202020202E6D706C75732D616374696F6E73202E6D706C75732D62746E2D2D69636F6E207B2077696474683A20322E323572656D3B207D0A7D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(12125750228788961)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_file_name=>'css/mediaPlus.css'
,p_mime_type=>'text/css'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A204D65646961506C757320666F72204F7261636C652041504558202D206974656D20706C75672D696E2076322E302E302028617564696F2C20766964656F2C2070686F746F7329207C204D4954207C204861736861616D2053686F756B61';
wwv_flow_imp.g_varchar2_table(2) := '740A202A20436F6C6F75727320636F6D652066726F6D20556E6976657273616C205468656D65207661726961626C65732C20736F205468656D6520526F6C6C6572207374796C657320616E64206461726B206D6F6465206170706C792E0A202A2F2E6D70';
wwv_flow_imp.g_varchar2_table(3) := '6C75737B2D2D6D706C75732D62673A20766172282D2D75742D636F6D706F6E656E742D6261636B67726F756E642D636F6C6F722C2023666666293B2D2D6D706C75732D626F726465723A20766172282D2D75742D636F6D706F6E656E742D626F72646572';
wwv_flow_imp.g_varchar2_table(4) := '2D636F6C6F722C207267626128302C20302C20302C202E313229293B2D2D6D706C75732D746578743A20766172282D2D75742D636F6D706F6E656E742D746578742D64656661756C742D636F6C6F722C20696E6865726974293B2D2D6D706C75732D6D75';
wwv_flow_imp.g_varchar2_table(5) := '7465643A20766172282D2D75742D636F6D706F6E656E742D746578742D6D757465642D636F6C6F722C207267626128302C20302C20302C202E3629293B2D2D6D706C75732D737562746C653A20766172282D2D75742D636F6D706F6E656E742D68696768';
wwv_flow_imp.g_varchar2_table(6) := '6C696768742D6261636B67726F756E642D636F6C6F722C207267626128302C20302C20302C202E30333529293B2D2D6D706C75732D616363656E743A20766172282D2D75742D70616C657474652D7072696D6172792C2023303537326365293B2D2D6D70';
wwv_flow_imp.g_varchar2_table(7) := '6C75732D6F6E2D616363656E743A20766172282D2D75742D70616C657474652D7072696D6172792D636F6E74726173742C2023666666293B2D2D6D706C75732D64616E6765723A20766172282D2D75742D70616C657474652D64616E6765722C20236362';
wwv_flow_imp.g_varchar2_table(8) := '31313030293B2D2D6D706C75732D7761726E3A20766172282D2D75742D70616C657474652D7761726E696E672C2023666263653461293B2D2D6D706C75732D737563636573733A20766172282D2D75742D70616C657474652D737563636573732C202332';
wwv_flow_imp.g_varchar2_table(9) := '3738373031293B2D2D6D706C75732D7261646975733A20766172282D2D75742D636F6D706F6E656E742D626F726465722D7261646975732C20387078293B2D2D6D706C75732D776176653A20766172282D2D6D706C75732D64616E676572293B2D2D6D70';
wwv_flow_imp.g_varchar2_table(10) := '6C75732D776176652D69646C653A20766172282D2D6D706C75732D6D75746564293B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E36323572656D3B70616464696E673A2E373572656D3B626F7264';
wwv_flow_imp.g_varchar2_table(11) := '65723A31707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B6261636B67726F756E643A766172282D2D6D706C75732D6267293B636F6C6F723A';
wwv_flow_imp.g_varchar2_table(12) := '766172282D2D6D706C75732D74657874293B6D696E2D77696474683A303B77696474683A313030253B626F782D73697A696E673A626F726465722D626F787D2E6D706C7573205B68696464656E5D7B646973706C61793A6E6F6E6521696D706F7274616E';
wwv_flow_imp.g_varchar2_table(13) := '747D2E6D706C75732D2D726F7B70616464696E673A2E323572656D20303B626F726465723A303B6261636B67726F756E643A7472616E73706172656E747D2E6D706C75732D2D64697361626C6564202E6D706C75732D616374696F6E732C2E6D706C7573';
wwv_flow_imp.g_varchar2_table(14) := '2D2D64697361626C6564202E6D706C75732D7365677B6F7061636974793A2E35353B706F696E7465722D6576656E74733A6E6F6E657D2E6D706C75732D746F707B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573';
wwv_flow_imp.g_varchar2_table(15) := '746966792D636F6E74656E743A73706163652D6265747765656E3B6761703A2E3572656D3B666C65782D777261703A777261707D2E6D706C75732D7365677B646973706C61793A696E6C696E652D666C65783B626F726465723A31707820736F6C696420';
wwv_flow_imp.g_varchar2_table(16) := '766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A39393970783B70616464696E673A3270783B6761703A3270783B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65297D2E6D706C75732D7365';
wwv_flow_imp.g_varchar2_table(17) := '67202E6D706C75732D62746E7B6865696768743A312E373572656D3B626F726465723A303B6261636B67726F756E643A7472616E73706172656E743B636F6C6F723A766172282D2D6D706C75732D6D75746564293B626F782D736861646F773A6E6F6E65';
wwv_flow_imp.g_varchar2_table(18) := '7D2E6D706C75732D736567202E6D706C75732D62746E5B617269612D707265737365643D747275655D7B6261636B67726F756E643A766172282D2D6D706C75732D616363656E74293B636F6C6F723A766172282D2D6D706C75732D6F6E2D616363656E74';
wwv_flow_imp.g_varchar2_table(19) := '293B6F7061636974793A317D2E6D706C75732D6C616E677B6865696768743A312E373572656D3B70616464696E673A30202E3572656D3B626F726465723A31707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D72';
wwv_flow_imp.g_varchar2_table(20) := '61646975733A39393970783B6261636B67726F756E643A766172282D2D6D706C75732D6267293B636F6C6F723A766172282D2D6D706C75732D74657874293B666F6E743A696E68657269743B666F6E742D73697A653A2E3831323572656D3B6D61782D77';
wwv_flow_imp.g_varchar2_table(21) := '696474683A313272656D7D2E6D706C75732D7374617475737B646973706C61793A696E6C696E652D666C65783B616C69676E2D6974656D733A63656E7465723B6761703A2E33373572656D3B6D617267696E2D696E6C696E652D73746172743A6175746F';
wwv_flow_imp.g_varchar2_table(22) := '3B70616464696E673A2E31323572656D202E36323572656D3B626F726465722D7261646975733A39393970783B666F6E742D73697A653A2E373572656D3B666F6E742D7765696768743A3630303B6C696E652D6865696768743A312E3572656D3B626163';
wwv_flow_imp.g_varchar2_table(23) := '6B67726F756E643A766172282D2D6D706C75732D737562746C65293B636F6C6F723A766172282D2D6D706C75732D6D75746564297D2E6D706C75732D7374617475732D2D7265636F7264696E677B6261636B67726F756E643A636F6C6F722D6D69782869';
wwv_flow_imp.g_varchar2_table(24) := '6E20737267622C766172282D2D6D706C75732D64616E67657229203134252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D64616E676572297D2E6D706C75732D7374617475732D2D7265636F7264696E673A6265666F72';
wwv_flow_imp.g_varchar2_table(25) := '657B636F6E74656E743A22223B77696474683A2E3572656D3B6865696768743A2E3572656D3B626F726465722D7261646975733A3530253B6261636B67726F756E643A63757272656E74436F6C6F723B616E696D6174696F6E3A6D706C75732D70756C73';
wwv_flow_imp.g_varchar2_table(26) := '6520312E327320656173652D696E2D6F757420696E66696E6974657D2E6D706C75732D7374617475732D2D7061757365647B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D7761726E2920333025';
wwv_flow_imp.g_varchar2_table(27) := '2C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D74657874297D2E6D706C75732D7374617475732D2D75706C6F6164696E672C2E6D706C75732D7374617475732D2D7265766965777B6261636B67726F756E643A636F6C6F';
wwv_flow_imp.g_varchar2_table(28) := '722D6D697828696E20737267622C766172282D2D6D706C75732D616363656E7429203134252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D616363656E74297D2E6D706C75732D73746167657B706F736974696F6E3A72';
wwv_flow_imp.g_varchar2_table(29) := '656C61746976653B6F766572666C6F773A68696464656E3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573297D2E6D706C75732D2D766964656F202E6D706C75732D73746167657B6261636B67726F756E643A23303030';
wwv_flow_imp.g_varchar2_table(30) := '3B6173706563742D726174696F3A3136202F20393B6D61782D6865696768743A363076683B77696474683A313030253B6D617267696E2D696E6C696E653A6175746F7D2E6D706C75732D2D766964656F202E6D706C75732D6C6976657B646973706C6179';
wwv_flow_imp.g_varchar2_table(31) := '3A626C6F636B3B77696474683A313030253B6865696768743A313030253B6F626A6563742D6669743A636F6E7461696E3B6261636B67726F756E643A233030307D2E6D706C75732D2D6D6972726F72202E6D706C75732D6C6976657B7472616E73666F72';
wwv_flow_imp.g_varchar2_table(32) := '6D3A7363616C6558282D31297D2E6D706C75732D2D617564696F202E6D706C75732D73746167657B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6761703A2E373572656D3B6865696768743A3572656D3B7061646469';
wwv_flow_imp.g_varchar2_table(33) := '6E673A30202E38373572656D3B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65297D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D73746167657B6865696768743A3372656D7D2E6D';
wwv_flow_imp.g_varchar2_table(34) := '706C75732D776176657B666C65783A312031206175746F3B6D696E2D77696474683A303B6865696768743A3730253B646973706C61793A626C6F636B7D5B6469723D72746C5D202E6D706C75732D776176657B7472616E73666F726D3A7363616C655828';
wwv_flow_imp.g_varchar2_table(35) := '2D31297D2E6D706C75732D6F7665726C61797B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6761703A2E3572656D7D2E6D706C75732D2D617564696F202E6D706C75732D6F7665726C61797B6F726465723A2D313B66';
wwv_flow_imp.g_varchar2_table(36) := '6C65783A302030206175746F7D2E6D706C75732D2D766964656F202E6D706C75732D6F7665726C61797B706F736974696F6E3A6162736F6C7574653B696E7365742D696E6C696E653A2E36323572656D3B746F703A2E36323572656D3B6A757374696679';
wwv_flow_imp.g_varchar2_table(37) := '2D636F6E74656E743A73706163652D6265747765656E3B706F696E7465722D6576656E74733A6E6F6E657D2E6D706C75732D7265637B646973706C61793A696E6C696E652D666C65783B616C69676E2D6974656D733A63656E7465723B6761703A2E3472';
wwv_flow_imp.g_varchar2_table(38) := '656D3B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D733B666F6E742D7765696768743A3630307D2E6D706C75732D2D617564696F202E6D706C75732D7265637B666F6E742D73697A653A312E3572656D7D2E6D706C75';
wwv_flow_imp.g_varchar2_table(39) := '732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D7265637B666F6E742D73697A653A312E31323572656D7D2E6D706C75732D2D766964656F202E6D706C75732D7265637B70616464696E673A2E31323572656D202E3572656D';
wwv_flow_imp.g_varchar2_table(40) := '3B626F726465722D7261646975733A39393970783B6261636B67726F756E643A2330303030303038633B636F6C6F723A236666663B666F6E742D73697A653A2E38373572656D7D2E6D706C75732D646F747B77696474683A2E36323572656D3B68656967';
wwv_flow_imp.g_varchar2_table(41) := '68743A2E36323572656D3B626F726465722D7261646975733A3530253B6261636B67726F756E643A766172282D2D6D706C75732D6D75746564297D2E6D706C75735B646174612D73746174653D7265636F7264696E675D202E6D706C75732D646F747B62';
wwv_flow_imp.g_varchar2_table(42) := '61636B67726F756E643A766172282D2D6D706C75732D64616E676572293B616E696D6174696F6E3A6D706C75732D70756C736520312E327320656173652D696E2D6F757420696E66696E6974657D2E6D706C75735B646174612D73746174653D70617573';
wwv_flow_imp.g_varchar2_table(43) := '65645D202E6D706C75732D646F747B6261636B67726F756E643A766172282D2D6D706C75732D7761726E297D2E6D706C75732D2D766964656F202E6D706C75732D646F747B6261636B67726F756E643A2366666666666662337D2E6D706C75732D2D7669';
wwv_flow_imp.g_varchar2_table(44) := '64656F5B646174612D73746174653D7265636F7264696E675D202E6D706C75732D646F747B6261636B67726F756E643A236666336233307D2E6D706C75732D6C6576656C7B77696474683A342E3572656D3B6865696768743A2E33373572656D3B626F72';
wwv_flow_imp.g_varchar2_table(45) := '6465722D7261646975733A39393970783B6261636B67726F756E643A2366666666666634643B6F766572666C6F773A68696464656E7D2E6D706C75732D6C6576656C3E7370616E7B646973706C61793A626C6F636B3B6865696768743A313030253B7769';
wwv_flow_imp.g_varchar2_table(46) := '6474683A303B6261636B67726F756E643A233334633735393B7472616E736974696F6E3A7769647468202E303873206C696E6561727D2E6D706C75732D636F756E74646F776E7B706F736974696F6E3A6162736F6C7574653B696E7365743A303B646973';
wwv_flow_imp.g_varchar2_table(47) := '706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B706F696E7465722D6576656E74733A6E6F6E653B666F6E742D73697A653A3472656D3B666F6E742D7765696768743A37';
wwv_flow_imp.g_varchar2_table(48) := '30303B636F6C6F723A236666663B746578742D736861646F773A30203270782031327078207267626128302C302C302C2E36297D2E6D706C75732D2D617564696F202E6D706C75732D636F756E74646F776E7B636F6C6F723A766172282D2D6D706C7573';
wwv_flow_imp.g_varchar2_table(49) := '2D616363656E74293B666F6E742D73697A653A322E3572656D3B746578742D736861646F773A6E6F6E657D2E6D706C75732D636F756E74646F776E3A656D7074797B646973706C61793A6E6F6E657D2E6D706C75732D6D657465727B646973706C61793A';
wwv_flow_imp.g_varchar2_table(50) := '666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E323572656D7D2E6D706C75732D6D657465722D747261636B7B646973706C61793A626C6F636B3B6865696768743A2E33373572656D3B626F726465722D7261646975733A';
wwv_flow_imp.g_varchar2_table(51) := '39393970783B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65293B6F766572666C6F773A68696464656E3B626F782D736861646F773A696E7365742030203020302031707820766172282D2D6D706C75732D626F72646572297D';
wwv_flow_imp.g_varchar2_table(52) := '2E6D706C75732D6D657465722D66696C6C7B646973706C61793A626C6F636B3B6865696768743A313030253B77696474683A303B6261636B67726F756E643A766172282D2D6D706C75732D616363656E74293B7472616E736974696F6E3A776964746820';
wwv_flow_imp.g_varchar2_table(53) := '2E32357320656173652C6261636B67726F756E642D636F6C6F72202E32357320656173657D2E6D706C75732D6D657465722E69732D7761726E202E6D706C75732D6D657465722D66696C6C7B6261636B67726F756E643A766172282D2D6D706C75732D64';
wwv_flow_imp.g_varchar2_table(54) := '616E676572297D2E6D706C75732D6D657465722D746578747B666F6E742D73697A653A2E373572656D3B636F6C6F723A766172282D2D6D706C75732D6D75746564293B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D73';
wwv_flow_imp.g_varchar2_table(55) := '7D2E6D706C75732D6D657465722E69732D7761726E202E6D706C75732D6D657465722D746578747B636F6C6F723A766172282D2D6D706C75732D64616E676572293B666F6E742D7765696768743A3630307D2E6D706C75732D6E6F746963657B64697370';
wwv_flow_imp.g_varchar2_table(56) := '6C61793A666C65783B616C69676E2D6974656D733A666C65782D73746172743B6761703A2E3572656D3B70616464696E673A2E3572656D202E373572656D3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B666F6E';
wwv_flow_imp.g_varchar2_table(57) := '742D73697A653A2E3831323572656D3B6C696E652D6865696768743A312E343B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D616363656E7429203130252C7472616E73706172656E74297D2E6D';
wwv_flow_imp.g_varchar2_table(58) := '706C75732D6E6F746963653A656D7074797B646973706C61793A6E6F6E657D2E6D706C75732D6E6F74696365202E742D49636F6E7B6D617267696E2D746F703A2E31323572656D7D2E6D706C75732D6E6F746963652D2D7761726E7B6261636B67726F75';
wwv_flow_imp.g_varchar2_table(59) := '6E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D7761726E29203234252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D74657874297D2E6D706C75732D6E6F746963652D2D7761726E20';
wwv_flow_imp.g_varchar2_table(60) := '2E742D49636F6E7B636F6C6F723A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D7761726E29203635252C23303030297D2E6D706C75732D6E6F746963652D2D6572726F727B6261636B67726F756E643A636F6C6F722D6D69';
wwv_flow_imp.g_varchar2_table(61) := '7828696E20737267622C766172282D2D6D706C75732D64616E67657229203132252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D64616E676572297D2E6D706C75732D616374696F6E737B646973706C61793A666C6578';
wwv_flow_imp.g_varchar2_table(62) := '3B616C69676E2D6974656D733A63656E7465723B666C65782D777261703A777261703B6761703A2E3572656D7D2E6D706C75732D62746E7B646973706C61793A696E6C696E652D666C65783B616C69676E2D6974656D733A63656E7465723B6A75737469';
wwv_flow_imp.g_varchar2_table(63) := '66792D636F6E74656E743A63656E7465723B6761703A2E33373572656D3B6865696768743A3272656D3B6D617267696E3A303B70616464696E673A30202E38373572656D2030202E36323572656D3B626F726465723A31707820736F6C69642076617228';
wwv_flow_imp.g_varchar2_table(64) := '2D2D6D706C75732D626F72646572293B626F726465722D7261646975733A39393970783B6261636B67726F756E643A766172282D2D6D706C75732D6267293B636F6C6F723A766172282D2D6D706C75732D74657874293B666F6E743A696E68657269743B';
wwv_flow_imp.g_varchar2_table(65) := '666F6E742D73697A653A2E3831323572656D3B666F6E742D7765696768743A3630303B6C696E652D6865696768743A313B77686974652D73706163653A6E6F777261703B746578742D6465636F726174696F6E3A6E6F6E653B637572736F723A706F696E';
wwv_flow_imp.g_varchar2_table(66) := '7465723B626F782D736861646F773A302031707820327078202330303030303030663B7472616E736974696F6E3A6261636B67726F756E642D636F6C6F72202E31357320656173652C626F726465722D636F6C6F72202E31357320656173652C626F782D';
wwv_flow_imp.g_varchar2_table(67) := '736861646F77202E31357320656173652C7472616E73666F726D202E30387320656173657D2E6D706C75732D62746E3A686F7665727B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65293B746578742D6465636F726174696F6E';
wwv_flow_imp.g_varchar2_table(68) := '3A6E6F6E653B636F6C6F723A766172282D2D6D706C75732D74657874297D2E6D706C75732D62746E3A6163746976657B7472616E73666F726D3A7363616C65282E3937297D2E6D706C75732D62746E3A666F6375732D76697369626C657B6F75746C696E';
wwv_flow_imp.g_varchar2_table(69) := '653A32707820736F6C696420766172282D2D6D706C75732D616363656E74293B6F75746C696E652D6F66667365743A3270787D2E6D706C75732D62746E5B64697361626C65645D7B6F7061636974793A2E34353B637572736F723A64656661756C743B74';
wwv_flow_imp.g_varchar2_table(70) := '72616E73666F726D3A6E6F6E657D2E6D706C75732D62746E2D2D7265632C2E6D706C75732D62746E2D2D73746F707B6261636B67726F756E643A766172282D2D6D706C75732D64616E676572293B626F726465722D636F6C6F723A766172282D2D6D706C';
wwv_flow_imp.g_varchar2_table(71) := '75732D64616E676572293B636F6C6F723A236666663B626F782D736861646F773A302032707820387078202D32707820636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D64616E67657229203630252C7472616E73706172656E';
wwv_flow_imp.g_varchar2_table(72) := '74297D2E6D706C75732D62746E2D2D7265633A686F7665722C2E6D706C75732D62746E2D2D73746F703A686F7665727B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D64616E6765722920383625';
wwv_flow_imp.g_varchar2_table(73) := '2C23303030293B636F6C6F723A236666667D2E6D706C75732D62746E2D2D7072696D6172797B6261636B67726F756E643A766172282D2D6D706C75732D616363656E74293B626F726465722D636F6C6F723A766172282D2D6D706C75732D616363656E74';
wwv_flow_imp.g_varchar2_table(74) := '293B636F6C6F723A766172282D2D6D706C75732D6F6E2D616363656E74297D2E6D706C75732D62746E2D2D7072696D6172793A686F7665727B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D6163';
wwv_flow_imp.g_varchar2_table(75) := '63656E7429203836252C23303030293B636F6C6F723A766172282D2D6D706C75732D6F6E2D616363656E74297D2E6D706C75732D62746E2D2D67686F73747B626F726465722D636F6C6F723A7472616E73706172656E743B6261636B67726F756E643A74';
wwv_flow_imp.g_varchar2_table(76) := '72616E73706172656E743B626F782D736861646F773A6E6F6E657D2E6D706C75732D62746E2D2D69636F6E7B77696474683A3272656D3B70616464696E673A307D2E6D706C75732D62746E2D2D69636F6E202E6D706C75732D62746E2D6C6162656C7B70';
wwv_flow_imp.g_varchar2_table(77) := '6F736974696F6E3A6162736F6C7574653B77696474683A3170783B6865696768743A3170783B6F766572666C6F773A68696464656E3B636C69703A726563742830203020302030293B77686974652D73706163653A6E6F777261707D2E6D706C75732D69';
wwv_flow_imp.g_varchar2_table(78) := '7B706F736974696F6E3A72656C61746976653B646973706C61793A696E6C696E652D626C6F636B3B666C65783A6E6F6E653B77696474683A2E38373572656D3B6865696768743A2E38373572656D3B666F6E742D73697A653A2E38373572656D3B6C696E';
wwv_flow_imp.g_varchar2_table(79) := '652D6865696768743A2E38373572656D3B746578742D616C69676E3A63656E7465727D2E6D706C75732D692D2D7265633A6265666F72657B636F6E74656E743A22223B706F736974696F6E3A6162736F6C7574653B696E7365743A2E31323572656D3B62';
wwv_flow_imp.g_varchar2_table(80) := '6F726465722D7261646975733A3530253B6261636B67726F756E643A63757272656E74436F6C6F727D2E6D706C75732D692D2D73746F703A6265666F72657B636F6E74656E743A22223B706F736974696F6E3A6162736F6C7574653B696E7365743A2E31';
wwv_flow_imp.g_varchar2_table(81) := '38373572656D3B626F726465722D7261646975733A3270783B6261636B67726F756E643A63757272656E74436F6C6F727D2E6D706C75732D692D2D70617573653A6265666F72652C2E6D706C75732D692D2D70617573653A61667465727B636F6E74656E';
wwv_flow_imp.g_varchar2_table(82) := '743A22223B706F736974696F6E3A6162736F6C7574653B746F703A2E31323572656D3B626F74746F6D3A2E31323572656D3B77696474683A3370783B626F726465722D7261646975733A3170783B6261636B67726F756E643A63757272656E74436F6C6F';
wwv_flow_imp.g_varchar2_table(83) := '727D2E6D706C75732D692D2D70617573653A6265666F72657B6C6566743A3270787D2E6D706C75732D692D2D70617573653A61667465727B72696768743A3270787D2E6D706C75732D692D2D706C61793A6265666F72657B636F6E74656E743A22223B70';
wwv_flow_imp.g_varchar2_table(84) := '6F736974696F6E3A6162736F6C7574653B696E7365743A2E31323572656D202E3036323572656D202E31323572656D202E323572656D3B6261636B67726F756E643A63757272656E74436F6C6F723B636C69702D706174683A706F6C79676F6E28302030';
wwv_flow_imp.g_varchar2_table(85) := '2C31303025203530252C302031303025297D5B6469723D72746C5D202E6D706C75732D692D2D706C61793A6265666F72657B7472616E73666F726D3A7363616C6558282D31297D2E6D706C75732D622D636C6F73657B6D617267696E2D696E6C696E652D';
wwv_flow_imp.g_varchar2_table(86) := '73746172743A6175746F7D2E6D706C75732D62746E2D2D7468656D657B6D617267696E3A307D2E6D706C75732D62746E2D2D7468656D65202E6D706C75732D697B6D617267696E2D696E6C696E652D656E643A2E33373572656D7D2E6D706C75732D6274';
wwv_flow_imp.g_varchar2_table(87) := '6E2D2D7468656D652E742D427574746F6E2D2D6E6F4C6162656C202E6D706C75732D697B6D617267696E3A307D2E6D706C75732D62746E2D2D7468656D65202E6D706C75732D62746E2D6C6162656C3A656D7074797B646973706C61793A6E6F6E657D2E';
wwv_flow_imp.g_varchar2_table(88) := '6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F7B646973706C61793A677269643B677269642D74656D706C6174652D636F6C756D6E733A6D696E6D617828302C31667229206175746F3B636F6C756D6E2D6761703A2E3572656D3B72';
wwv_flow_imp.g_varchar2_table(89) := '6F772D6761703A303B616C69676E2D6974656D733A63656E7465723B677269642D74656D706C6174652D61726561733A22746F7020746F70222022737461676520616374696F6E73222022737474207374742220226D65746572206D657465722220226E';
wwv_flow_imp.g_varchar2_table(90) := '6F74696365206E6F746963652220227265766965772072657669657722202268696E742068696E742220226C697374206C697374227D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D746F707B677269642D61';
wwv_flow_imp.g_varchar2_table(91) := '7265613A746F703B6D617267696E2D626F74746F6D3A2E3572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D73746167657B677269642D617265613A73746167653B6865696768743A322E3572656D3B';
wwv_flow_imp.g_varchar2_table(92) := '70616464696E673A30202E36323572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D616374696F6E732D2D6D61696E7B677269642D617265613A616374696F6E733B666C65782D777261703A6E6F7772';
wwv_flow_imp.g_varchar2_table(93) := '61707D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D7374747B677269642D617265613A7374743B6D617267696E2D746F703A2E3572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564';
wwv_flow_imp.g_varchar2_table(94) := '696F3E2E6D706C75732D6D657465727B677269642D617265613A6D657465723B6D617267696E2D746F703A2E33373572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D6E6F746963657B677269642D61';
wwv_flow_imp.g_varchar2_table(95) := '7265613A6E6F746963653B6D617267696E2D746F703A2E3572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D7265766965777B677269642D617265613A7265766965777D2E6D706C75732D2D636F6D70';
wwv_flow_imp.g_varchar2_table(96) := '6163742E6D706C75732D2D617564696F3E2E6D706C75732D68696E747B677269642D617265613A68696E743B6D617267696E2D746F703A2E33373572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F3E2E6D706C75732D6C';
wwv_flow_imp.g_varchar2_table(97) := '6973747B677269642D617265613A6C6973743B6D617267696E2D746F703A2E36323572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F5B646174612D73746174653D69646C655D3E2E6D706C75732D616374696F6E732D2D';
wwv_flow_imp.g_varchar2_table(98) := '6D61696E7B677269642D617265613A6175746F3B677269642D636F6C756D6E3A31202F202D313B677269642D726F773A323B666C65782D777261703A777261707D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C7573';
wwv_flow_imp.g_varchar2_table(99) := '2D7374616765202E6D706C75732D7265637B666F6E742D73697A653A3172656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D70617573652C2E6D706C75732D2D636F6D706163742E6D706C75732D2D';
wwv_flow_imp.g_varchar2_table(100) := '617564696F202E6D706C75732D622D73746F707B77696474683A3272656D3B70616464696E673A307D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D7061757365202E6D706C75732D62746E2D6C616265';
wwv_flow_imp.g_varchar2_table(101) := '6C2C2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D622D73746F70202E6D706C75732D62746E2D6C6162656C7B706F736974696F6E3A6162736F6C7574653B77696474683A3170783B6865696768743A317078';
wwv_flow_imp.g_varchar2_table(102) := '3B6F766572666C6F773A68696464656E3B636C69703A726563742830203020302030293B77686974652D73706163653A6E6F777261707D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D6D657465727B676170';
wwv_flow_imp.g_varchar2_table(103) := '3A2E31323572656D7D2E6D706C75732D2D636F6D706163742E6D706C75732D2D617564696F202E6D706C75732D6D657465722D747261636B7B6865696768743A2E323572656D7D2E6D706C75732D66696C657B646973706C61793A6E6F6E657D2E6D706C';
wwv_flow_imp.g_varchar2_table(104) := '75732D68696E747B666F6E742D73697A653A2E373572656D3B636F6C6F723A766172282D2D6D706C75732D6D75746564297D2E6D706C75732D7265766965777B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B67';
wwv_flow_imp.g_varchar2_table(105) := '61703A2E3572656D3B70616464696E673A2E373572656D3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B626F726465723A3170782064617368656420636F6C6F722D6D697828696E20737267622C766172282D2D';
wwv_flow_imp.g_varchar2_table(106) := '6D706C75732D616363656E7429203535252C7472616E73706172656E74293B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D616363656E74292035252C7472616E73706172656E74297D2E6D706C';
wwv_flow_imp.g_varchar2_table(107) := '75732D7265766965772D7469746C657B666F6E742D73697A653A2E3831323572656D3B666F6E742D7765696768743A3630307D2E6D706C75732D7265766965772D6D6574617B666F6E742D73697A653A2E373572656D3B636F6C6F723A766172282D2D6D';
wwv_flow_imp.g_varchar2_table(108) := '706C75732D6D75746564293B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D737D2E6D706C75732D6D656469617B646973706C61793A626C6F636B3B77696474683A313030253B626F726465722D7261646975733A7661';
wwv_flow_imp.g_varchar2_table(109) := '72282D2D6D706C75732D726164697573297D766964656F2E6D706C75732D6D656469617B6261636B67726F756E643A233030303B6D61782D6865696768743A353576687D617564696F2E6D706C75732D6D656469617B6865696768743A322E3572656D7D';
wwv_flow_imp.g_varchar2_table(110) := '2E6D706C75732D6C6973747B6C6973742D7374796C653A6E6F6E653B6D617267696E3A303B70616464696E673A303B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E33373572656D7D2E6D706C7573';
wwv_flow_imp.g_varchar2_table(111) := '2D726F777B646973706C61793A677269643B677269642D74656D706C6174652D636F6C756D6E733A6175746F206D696E6D617828302C31667229206175746F3B616C69676E2D6974656D733A63656E7465723B6761703A2E323572656D202E3632357265';
wwv_flow_imp.g_varchar2_table(112) := '6D3B70616464696E673A2E3572656D202E3572656D202E3572656D202E36323572656D3B626F726465723A31707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A766172282D2D6D706C75732D72';
wwv_flow_imp.g_varchar2_table(113) := '6164697573293B6261636B67726F756E643A766172282D2D6D706C75732D6267297D2E6D706C75732D2D726F202E6D706C75732D726F777B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65297D2E6D706C75732D726F772D6963';
wwv_flow_imp.g_varchar2_table(114) := '6F7B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B6A7573746966792D636F6E74656E743A63656E7465723B77696474683A322E323572656D3B6865696768743A322E323572656D3B626F726465722D7261646975733A';
wwv_flow_imp.g_varchar2_table(115) := '3530253B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D616363656E7429203132252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D616363656E74297D2E6D706C';
wwv_flow_imp.g_varchar2_table(116) := '75732D726F772D69636F202E66617B646973706C61793A626C6F636B3B666F6E742D73697A653A3172656D3B6C696E652D6865696768743A313B77696474683A6175746F3B6865696768743A6175746F7D2E6D706C75732D726F772D746578747B677269';
wwv_flow_imp.g_varchar2_table(117) := '642D636F6C756D6E3A32202F202D313B666F6E742D73697A653A2E3831323572656D3B6C696E652D6865696768743A312E34353B636F6C6F723A766172282D2D6D706C75732D74657874293B77686974652D73706163653A7072652D777261703B646973';
wwv_flow_imp.g_varchar2_table(118) := '706C61793A2D7765626B69742D626F783B2D7765626B69742D6C696E652D636C616D703A333B2D7765626B69742D626F782D6F7269656E743A766572746963616C3B6F766572666C6F773A68696464656E7D2E6D706C75732D7374747B70616464696E67';
wwv_flow_imp.g_varchar2_table(119) := '3A2E3572656D202E373572656D3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65293B666F6E742D73697A653A2E38373572656D3B6C696E';
wwv_flow_imp.g_varchar2_table(120) := '652D6865696768743A312E353B6D61782D6865696768743A372E3572656D3B6F766572666C6F772D793A6175746F7D2E6D706C75732D7374742D696E746572696D7B636F6C6F723A766172282D2D6D706C75732D6D75746564293B666F6E742D7374796C';
wwv_flow_imp.g_varchar2_table(121) := '653A6974616C69637D2E6D706C75732D7472616E7363726970742D626F787B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E323572656D7D2E6D706C75732D7472616E7363726970742D6C6162656C';
wwv_flow_imp.g_varchar2_table(122) := '7B666F6E742D73697A653A2E373572656D3B666F6E742D7765696768743A3630303B636F6C6F723A766172282D2D6D706C75732D6D75746564297D2E6D706C75732D7472616E7363726970747B77696474683A313030253B626F782D73697A696E673A62';
wwv_flow_imp.g_varchar2_table(123) := '6F726465722D626F783B6D696E2D6865696768743A342E3572656D3B726573697A653A766572746963616C3B70616464696E673A2E3572656D202E36323572656D3B666F6E743A696E68657269743B666F6E742D73697A653A2E38373572656D3B6C696E';
wwv_flow_imp.g_varchar2_table(124) := '652D6865696768743A312E34353B626F726465723A31707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B6261636B67726F756E643A76617228';
wwv_flow_imp.g_varchar2_table(125) := '2D2D6D706C75732D6267293B636F6C6F723A766172282D2D6D706C75732D74657874297D2E6D706C75732D7472616E7363726970743A666F6375737B6F75746C696E653A32707820736F6C696420766172282D2D6D706C75732D616363656E74293B6F75';
wwv_flow_imp.g_varchar2_table(126) := '746C696E652D6F66667365743A2D3170787D2E6D706C75732D726F772D6D61696E7B646973706C61793A666C65783B616C69676E2D6974656D733A63656E7465723B666C65782D777261703A777261703B6761703A2E31323572656D202E3572656D3B6D';
wwv_flow_imp.g_varchar2_table(127) := '696E2D77696474683A307D2E6D706C75732D726F772D6E616D657B666C65783A31203120313030253B6D696E2D77696474683A303B666F6E742D73697A653A2E3831323572656D3B666F6E742D7765696768743A3630303B6F766572666C6F773A686964';
wwv_flow_imp.g_varchar2_table(128) := '64656E3B746578742D6F766572666C6F773A656C6C69707369733B77686974652D73706163653A6E6F777261707D2E6D706C75732D726F772D6D6574617B666F6E742D73697A653A2E373572656D3B636F6C6F723A766172282D2D6D706C75732D6D7574';
wwv_flow_imp.g_varchar2_table(129) := '6564293B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D737D2E6D706C75732D7461677B666F6E742D73697A653A2E3638373572656D3B6C696E652D6865696768743A312E3172656D3B70616464696E673A30202E3472';
wwv_flow_imp.g_varchar2_table(130) := '656D3B626F726465722D7261646975733A39393970783B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65293B636F6C6F723A766172282D2D6D706C75732D6D75746564297D2E6D706C75732D7461672D2D73617665647B626163';
wwv_flow_imp.g_varchar2_table(131) := '6B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D7375636365737329203134252C7472616E73706172656E74293B636F6C6F723A766172282D2D6D706C75732D73756363657373297D2E6D706C75732D726F';
wwv_flow_imp.g_varchar2_table(132) := '772D70726F67726573737B666C65783A31203120313030253B6865696768743A2E323572656D3B626F726465722D7261646975733A39393970783B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65293B6F766572666C6F773A68';
wwv_flow_imp.g_varchar2_table(133) := '696464656E7D2E6D706C75732D726F772D70726F67726573733E7370616E7B646973706C61793A626C6F636B3B6865696768743A313030253B77696474683A303B6261636B67726F756E643A766172282D2D6D706C75732D616363656E74293B7472616E';
wwv_flow_imp.g_varchar2_table(134) := '736974696F6E3A7769647468202E327320656173657D2E6D706C75732D726F772D62746E737B646973706C61793A696E6C696E652D666C65783B616C69676E2D6974656D733A63656E7465723B6761703A2E31323572656D7D2E6D706C75732D726F772D';
wwv_flow_imp.g_varchar2_table(135) := '62746E73202E742D427574746F6E7B6D617267696E3A307D2E6D706C75732D722D64656C3A686F766572202E742D49636F6E7B636F6C6F723A766172282D2D6D706C75732D64616E676572297D2E6D706C75732D726F772D706C617965727B677269642D';
wwv_flow_imp.g_varchar2_table(136) := '636F6C756D6E3A31202F202D313B70616464696E672D746F703A2E323572656D7D2E6D706C75732D62746E2D2D736875747465727B6261636B67726F756E643A766172282D2D6D706C75732D616363656E74293B626F726465722D636F6C6F723A766172';
wwv_flow_imp.g_varchar2_table(137) := '282D2D6D706C75732D616363656E74293B636F6C6F723A766172282D2D6D706C75732D6F6E2D616363656E74297D2E6D706C75732D62746E2D2D736875747465723A686F7665727B6261636B67726F756E643A636F6C6F722D6D697828696E2073726762';
wwv_flow_imp.g_varchar2_table(138) := '2C766172282D2D6D706C75732D616363656E7429203836252C23303030293B636F6C6F723A766172282D2D6D706C75732D6F6E2D616363656E74297D2E6D706C75732D2D696D616765202E6D706C75732D73746167657B6173706563742D726174696F3A';
wwv_flow_imp.g_varchar2_table(139) := '34202F20337D2E6D706C75732D73746167652E69732D666C6173683A61667465727B636F6E74656E743A22223B706F736974696F6E3A6162736F6C7574653B696E7365743A303B6261636B67726F756E643A236666663B616E696D6174696F6E3A6D706C';
wwv_flow_imp.g_varchar2_table(140) := '75732D666C617368202E327320656173652D6F757420666F7277617264733B706F696E7465722D6576656E74733A6E6F6E657D2E6D706C75732D726F772D69636F7B6F766572666C6F773A68696464656E7D2E6D706C75732D726F772D2D696D61676520';
wwv_flow_imp.g_varchar2_table(141) := '2E6D706C75732D726F772D69636F7B626F726465722D7261646975733A3670787D2E6D706C75732D726F772D7468756D627B646973706C61793A626C6F636B3B77696474683A313030253B6865696768743A313030253B6F626A6563742D6669743A636F';
wwv_flow_imp.g_varchar2_table(142) := '7665727D2E6D706C75732D70686F746F7B646973706C61793A626C6F636B3B6D61782D77696474683A313030253B6D61782D6865696768743A363076683B6D617267696E3A30206175746F3B626F726465722D7261646975733A766172282D2D6D706C75';
wwv_flow_imp.g_varchar2_table(143) := '732D726164697573293B6261636B67726F756E643A766172282D2D6D706C75732D737562746C65297D2E6D706C75732D65647B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E3572656D7D2E6D706C';
wwv_flow_imp.g_varchar2_table(144) := '75732D65642D73746167657B646973706C61793A666C65783B6A7573746966792D636F6E74656E743A63656E7465723B70616464696E673A2E3572656D3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B6261636B';
wwv_flow_imp.g_varchar2_table(145) := '67726F756E643A726570656174696E672D636F6E69632D6772616469656E7428766172282D2D6D706C75732D737562746C65292030203235252C7472616E73706172656E742030203530252920353025202F203136707820313670787D2E6D706C75732D';
wwv_flow_imp.g_varchar2_table(146) := '65642D777261707B706F736974696F6E3A72656C61746976653B646973706C61793A696E6C696E652D626C6F636B3B6C696E652D6865696768743A303B6D61782D77696474683A313030253B746F7563682D616374696F6E3A6E6F6E653B757365722D73';
wwv_flow_imp.g_varchar2_table(147) := '656C6563743A6E6F6E653B2D7765626B69742D757365722D73656C6563743A6E6F6E657D2E6D706C75732D65642D63616E7661737B646973706C61793A626C6F636B3B6D61782D77696474683A313030253B6D61782D6865696768743A353576683B7769';
wwv_flow_imp.g_varchar2_table(148) := '6474683A6175746F3B6865696768743A6175746F7D2E6D706C75732D65642E69732D64726177696E67202E6D706C75732D65642D63616E7661737B637572736F723A63726F7373686169727D2E6D706C75732D65642D63726F707B706F736974696F6E3A';
wwv_flow_imp.g_varchar2_table(149) := '6162736F6C7574653B626F782D73697A696E673A626F726465722D626F783B626F726465723A32707820736F6C696420236666663B626F782D736861646F773A302030203020393939397078202330303030303038302C30203020302031707820233030';
wwv_flow_imp.g_varchar2_table(150) := '30363B637572736F723A6D6F76653B746F7563682D616374696F6E3A6E6F6E653B6F75746C696E653A6E6F6E653B6261636B67726F756E642D696D6167653A6C696E6561722D6772616469656E74282366666666666635392C236666666666663539292C';
wwv_flow_imp.g_varchar2_table(151) := '6C696E6561722D6772616469656E74282366666666666635392C236666666666663539292C6C696E6561722D6772616469656E74282366666666666635392C236666666666663539292C6C696E6561722D6772616469656E74282366666666666635392C';
wwv_flow_imp.g_varchar2_table(152) := '236666666666663539293B6261636B67726F756E642D73697A653A31707820313030252C31707820313030252C31303025203170782C31303025203170783B6261636B67726F756E642D706F736974696F6E3A33332E33332520302C36362E3636252030';
wwv_flow_imp.g_varchar2_table(153) := '2C302033332E3333252C302036362E3636253B6261636B67726F756E642D7265706561743A6E6F2D7265706561747D2E6D706C75732D65642D63726F703A666F6375732D76697369626C657B626F726465722D636F6C6F723A766172282D2D6D706C7573';
wwv_flow_imp.g_varchar2_table(154) := '2D616363656E74297D2E6D706C75732D65642D777261707B6F766572666C6F773A68696464656E7D2E6D706C75732D65642D687B706F736974696F6E3A6162736F6C7574653B77696474683A313670783B6865696768743A313670783B6261636B67726F';
wwv_flow_imp.g_varchar2_table(155) := '756E643A236666663B626F726465722D7261646975733A3370783B626F782D736861646F773A302031707820337078202330303030303038307D2E6D706C75732D65642D682D2D6E777B6C6566743A3270783B746F703A3270783B637572736F723A6E77';
wwv_flow_imp.g_varchar2_table(156) := '73652D726573697A657D2E6D706C75732D65642D682D2D6E657B72696768743A3270783B746F703A3270783B637572736F723A6E6573772D726573697A657D2E6D706C75732D65642D682D2D73657B72696768743A3270783B626F74746F6D3A3270783B';
wwv_flow_imp.g_varchar2_table(157) := '637572736F723A6E7773652D726573697A657D2E6D706C75732D65642D682D2D73777B6C6566743A3270783B626F74746F6D3A3270783B637572736F723A6E6573772D726573697A657D2E6D706C75732D65642D682D2D6E2C2E6D706C75732D65642D68';
wwv_flow_imp.g_varchar2_table(158) := '2D2D737B6C6566743A3530253B77696474683A323870783B6865696768743A3670783B6D617267696E2D6C6566743A2D313470783B637572736F723A6E732D726573697A657D2E6D706C75732D65642D682D2D6E7B746F703A3270787D2E6D706C75732D';
wwv_flow_imp.g_varchar2_table(159) := '65642D682D2D737B626F74746F6D3A3270787D2E6D706C75732D65642D682D2D652C2E6D706C75732D65642D682D2D777B746F703A3530253B77696474683A3670783B6865696768743A323870783B6D617267696E2D746F703A2D313470783B63757273';
wwv_flow_imp.g_varchar2_table(160) := '6F723A65772D726573697A657D2E6D706C75732D65642D682D2D657B72696768743A3270787D2E6D706C75732D65642D682D2D777B6C6566743A3270787D406D656469612028706F696E7465723A20636F61727365297B2E6D706C75732D65642D682D2D';
wwv_flow_imp.g_varchar2_table(161) := '6E772C2E6D706C75732D65642D682D2D6E652C2E6D706C75732D65642D682D2D73652C2E6D706C75732D65642D682D2D73777B77696474683A323270783B6865696768743A323270787D7D2E6D706C75732D65642D746F6F6C737B646973706C61793A66';
wwv_flow_imp.g_varchar2_table(162) := '6C65783B616C69676E2D6974656D733A63656E7465723B666C65782D777261703A777261703B6761703A2E323572656D7D2E6D706C75732D65642D746F6F6C73202E6D706C75732D62746E5B617269612D707265737365643D747275655D2C2E6D706C75';
wwv_flow_imp.g_varchar2_table(163) := '732D65642D746F6F6C73202E742D427574746F6E5B617269612D707265737365643D747275655D7B6261636B67726F756E643A636F6C6F722D6D697828696E20737267622C766172282D2D6D706C75732D616363656E7429203136252C7472616E737061';
wwv_flow_imp.g_varchar2_table(164) := '72656E74293B636F6C6F723A766172282D2D6D706C75732D616363656E74297D2E6D706C7573202E6D706C75732D65642D73656C6563742C2E6D706C7573202E6D706C75732D6C616E677B6F726465723A307D2E6D706C75732D65642D73656C6563747B';
wwv_flow_imp.g_varchar2_table(165) := '6865696768743A3272656D3B70616464696E673A30202E3572656D3B626F726465723A31707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A39393970783B6261636B67726F756E643A76617228';
wwv_flow_imp.g_varchar2_table(166) := '2D2D6D706C75732D6267293B636F6C6F723A766172282D2D6D706C75732D74657874293B666F6E743A696E68657269743B666F6E742D73697A653A2E3831323572656D7D2E6D706C7573202E6D706C75732D652D72657365747B6F726465723A313B6D61';
wwv_flow_imp.g_varchar2_table(167) := '7267696E2D696E6C696E652D73746172743A6175746F7D2E6D706C75732D65642D636F6C6F7572737B646973706C61793A696E6C696E652D666C65783B6761703A2E323572656D3B70616464696E673A30202E323572656D7D2E6D706C75732D65642D63';
wwv_flow_imp.g_varchar2_table(168) := '6F6C6F75727B77696474683A312E3572656D3B6865696768743A312E3572656D3B70616464696E673A303B626F726465723A32707820736F6C696420766172282D2D6D706C75732D626F72646572293B626F726465722D7261646975733A3530253B6375';
wwv_flow_imp.g_varchar2_table(169) := '72736F723A706F696E7465727D2E6D706C75732D65642D636F6C6F75725B617269612D707265737365643D747275655D7B626F726465722D636F6C6F723A766172282D2D6D706C75732D616363656E74293B626F782D736861646F773A30203020302032';
wwv_flow_imp.g_varchar2_table(170) := '707820766172282D2D6D706C75732D62672920696E7365747D2E6D706C75732D65642D61646A7573747B646973706C61793A677269643B677269642D74656D706C6174652D636F6C756D6E733A726570656174286175746F2D6669742C6D696E6D617828';
wwv_flow_imp.g_varchar2_table(171) := '313072656D2C31667229293B6761703A2E3572656D203172656D3B70616464696E673A2E3572656D202E373572656D3B626F726465722D7261646975733A766172282D2D6D706C75732D726164697573293B6261636B67726F756E643A766172282D2D6D';
wwv_flow_imp.g_varchar2_table(172) := '706C75732D737562746C65297D2E6D706C75732D65642D736C696465727B646973706C61793A666C65783B666C65782D646972656374696F6E3A636F6C756D6E3B6761703A2E31323572656D3B666F6E742D73697A653A2E373572656D3B636F6C6F723A';
wwv_flow_imp.g_varchar2_table(173) := '766172282D2D6D706C75732D6D75746564297D2E6D706C75732D65642D72616E67657B77696474683A313030253B616363656E742D636F6C6F723A766172282D2D6D706C75732D616363656E74297D2E6D706C75732D65642D6D6574617B666F6E742D73';
wwv_flow_imp.g_varchar2_table(174) := '697A653A2E373572656D3B636F6C6F723A766172282D2D6D706C75732D6D75746564293B666F6E742D76617269616E742D6E756D657269633A746162756C61722D6E756D737D406B65796672616D6573206D706C75732D666C6173687B30257B6F706163';
wwv_flow_imp.g_varchar2_table(175) := '6974793A2E397D746F7B6F7061636974793A307D7D406B65796672616D6573206D706C75732D70756C73657B30252C746F7B6F7061636974793A317D3530257B6F7061636974793A2E33357D7D406D656469612028707265666572732D72656475636564';
wwv_flow_imp.g_varchar2_table(176) := '2D6D6F74696F6E3A20726564756365297B2E6D706C75732D7374617475732D2D7265636F7264696E673A6265666F72652C2E6D706C75735B646174612D73746174653D7265636F7264696E675D202E6D706C75732D646F747B616E696D6174696F6E3A6E';
wwv_flow_imp.g_varchar2_table(177) := '6F6E657D7D406D6564696120286D61782D77696474683A203438307078297B2E6D706C75737B70616464696E673A2E36323572656D7D2E6D706C75732D616374696F6E73202E6D706C75732D62746E7B666C65783A312031206175746F3B686569676874';
wwv_flow_imp.g_varchar2_table(178) := '3A322E323572656D7D2E6D706C75732D616374696F6E73202E6D706C75732D62746E2D2D69636F6E2C2E6D706C75732D616374696F6E73202E6D706C75732D62746E2D2D67686F73747B666C65783A302030206175746F7D2E6D706C75732D616374696F';
wwv_flow_imp.g_varchar2_table(179) := '6E73202E6D706C75732D62746E2D2D69636F6E7B77696474683A322E323572656D7D7D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(12125891945788969)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_file_name=>'css/mediaPlus.min.css'
,p_mime_type=>'text/css'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A204D65646961506C757320666F72204F7261636C652041504558202D206974656D20706C75672D696E2076322E302E300A202A205265636F726420617564696F206F7220766964656F20616E642074616B652070686F746F7320696E2074';
wwv_flow_imp.g_varchar2_table(2) := '68652062726F77736572202D207265766965772C2063726F7020616E642061646A757374207468656D202D20616E64206B656570207468656D20696E20616E0A202A204150455820636F6C6C656374696F6E20756E74696C207468652070616765207361';
wwv_flow_imp.g_varchar2_table(3) := '766573207468656D2E0A202A202863292032303236204861736861616D2053686F756B6174202D204D4954204C6963656E73650A202A2F0A2F2A20676C6F62616C2061706578202A2F0A77696E646F772E6D65646961506C7573203D202866756E637469';
wwv_flow_imp.g_varchar2_table(4) := '6F6E20282429207B0A202020202275736520737472696374223B0A0A202020207661722056455253494F4E203D2022322E302E30222C0A2020202020202020504152545F4259544553203D20313537323836342C20202020202F2F206279746573207065';
wwv_flow_imp.g_varchar2_table(5) := '722075706C6F6164207265717565737420286D756C7469706C65206F6620332C20736F2065616368207061727420697320636C65616E20626173653634290A202020202020202050494543455F4348415253203D2033323030302C2020202020202F2F20';
wwv_flow_imp.g_varchar2_table(6) := '6261736536342063686172616374657273207065722066303120656C656D656E7420286D756C7469706C65206F662034290A2020202020202020504152414C4C454C203D20332C202020202020202020202020202F2F2075706C6F616420726571756573';
wwv_flow_imp.g_varchar2_table(7) := '747320617420612074696D650A20202020202020204D41585F5452414E534352495054203D2032303030302C0A202020202020202044524146545F44415953203D20372C20202020202020202020202F2F20756E7361766564207265636F7264696E6773';
wwv_flow_imp.g_varchar2_table(8) := '20617265206B65707420696E207468652062726F777365722074686973206C6F6E670A202020202020202050484F544F5F534F555243455F4D4158203D20343039362C20202F2F2070686F746F7320617265207363616C656420746F2074686973206C6F';
wwv_flow_imp.g_varchar2_table(9) := '6E676573742073696465206265666F72652065646974696E67202870686F6E652063616E766173206C696D697473290A20202020202020204C414E4753203D205B22656E2D5553222C202261722D5341225D2C2020202F2F207472616E73637269707469';
wwv_flow_imp.g_varchar2_table(10) := '6F6E206C616E677561676573206F6666657265640A2020202020202020696E7374616E636573203D207B7D3B0A0A202020202F2F205175616C69747920707265736574733A20617564696F206B6270732C20766964656F206B6270732C20766964656F20';
wwv_flow_imp.g_varchar2_table(11) := '6865696768742C206672616D657320706572207365636F6E640A202020207661722050524553455453203D207B0A2020202020202020534D414C4C3A202020207B20617564696F4B6270733A2032342C2020766964656F4B6270733A203335302C202076';
wwv_flow_imp.g_varchar2_table(12) := '6964656F4865696768743A203336302C206670733A203135207D2C0A202020202020202042414C414E4345443A207B20617564696F4B6270733A2034382C2020766964656F4B6270733A203930302C2020766964656F4865696768743A203438302C2066';
wwv_flow_imp.g_varchar2_table(13) := '70733A203234207D2C0A2020202020202020484947483A20202020207B20617564696F4B6270733A203132382C20766964656F4B6270733A20323530302C20766964656F4865696768743A203732302C206670733A203330207D0A202020207D3B0A0A20';
wwv_flow_imp.g_varchar2_table(14) := '2020202F2F20456E676C6973682074657874733B2065616368206F6E652063616E206265207472616E736C61746564207769746820616E206170706C69636174696F6E2074657874206D657373616765204D45444941504C55532E3C4B45593E0A202020';
wwv_flow_imp.g_varchar2_table(15) := '207661722054455854203D207B0A2020202020202020415544494F3A2022417564696F222C0A2020202020202020564944454F3A2022566964656F222C0A2020202020202020494D4147453A202250686F746F222C0A20202020202020204B494E44533A';
wwv_flow_imp.g_varchar2_table(16) := '20225768617420746F20616464222C0A20202020202020205245434F52443A20225265636F7264222C0A202020202020202054414B455F50484F544F3A202254616B652050686F746F222C0A2020202020202020434150545552453A2022436170747572';
wwv_flow_imp.g_varchar2_table(17) := '65222C0A20202020202020205553455F50484F544F3A20225573652050686F746F222C0A2020202020202020524554414B453A202254616B6520416761696E222C0A202020202020202050484F544F5F5449544C453A202243726F702C207475726E206F';
wwv_flow_imp.g_varchar2_table(18) := '722061646A757374207468652070686F746F2C207468656E207573652069742E222C0A2020202020202020524F544154455F4C4546543A2022526F74617465204C656674222C0A2020202020202020524F544154455F52494748543A2022526F74617465';
wwv_flow_imp.g_varchar2_table(19) := '205269676874222C0A2020202020202020464C49503A2022466C6970222C0A202020202020202043524F503A202243726F70222C0A202020202020202043524F505F465245453A202246726565222C0A202020202020202043524F505F414C4C3A202257';
wwv_flow_imp.g_varchar2_table(20) := '686F6C652050686F746F222C0A202020202020202041444A5553543A202241646A757374222C0A20202020202020204252494748544E4553533A20224272696768746E657373222C0A2020202020202020434F4E54524153543A2022436F6E7472617374';
wwv_flow_imp.g_varchar2_table(21) := '222C0A202020202020202053415455524154494F4E3A2022436F6C6F7572222C0A2020202020202020475241595343414C453A2022426C61636B20616E64205768697465222C0A2020202020202020445241573A202244726177222C0A20202020202020';
wwv_flow_imp.g_varchar2_table(22) := '20554E444F3A2022556E646F222C0A202020202020202052455345543A20225265736574222C0A202020202020202053495A453A202253697A65222C0A202020202020202053495A455F46554C4C3A202246756C6C2028253020707829222C0A20202020';
wwv_flow_imp.g_varchar2_table(23) := '2020202053495A455F50583A20222530207078222C0A202020202020202050484F544F5F4D4554413A2022253020C397202531207078222C0A202020202020202050484F544F5F53495A453A202261626F7574202530222C0A2020202020202020505245';
wwv_flow_imp.g_varchar2_table(24) := '504152494E473A2022507265706172696E67207468652070686F746F2E2E2E222C0A202020202020202050484F544F5F4641494C45443A2022546869732070686F746F20636F756C64206E6F74206265206F70656E65642E202530222C0A202020202020';
wwv_flow_imp.g_varchar2_table(25) := '202050484F544F5F544F4F5F4C415247453A20224576656E206D61646520736D616C6C65722C20746869732070686F746F206973206D6F7265207468616E2025302E2043726F70206974206F722063686F6F7365206120736D616C6C65722073697A652E';
wwv_flow_imp.g_varchar2_table(26) := '222C0A2020202020202020564945573A202256696577222C0A2020202020202020484944453A202248696465222C0A20202020202020204F50454E5F43414D4552413A20224F70656E2043616D657261222C0A202020202020202053544152543A202253';
wwv_flow_imp.g_varchar2_table(27) := '74617274205265636F7264696E67222C0A202020202020202050415553453A20225061757365222C0A2020202020202020524553554D453A2022526573756D65222C0A202020202020202053544F503A202253746F70222C0A202020202020202043414E';
wwv_flow_imp.g_varchar2_table(28) := '43454C3A202243616E63656C222C0A2020202020202020434C4F53455F43414D4552413A2022436C6F73652043616D657261222C0A20202020202020205357495443485F43414D4552413A20225377697463682043616D657261222C0A20202020202020';
wwv_flow_imp.g_varchar2_table(29) := '2043484F4F53455F46494C453A202243686F6F73652046696C65222C0A20202020202020204445564943455F5245434F524445523A202255736520446576696365205265636F72646572222C0A20202020202020205553453A2022557365205265636F72';
wwv_flow_imp.g_varchar2_table(30) := '64696E67222C0A202020202020202052455452593A202254727920416761696E222C0A2020202020202020414741494E3A20225265636F726420416761696E222C0A2020202020202020444953434152443A202244697363617264222C0A202020202020';
wwv_flow_imp.g_varchar2_table(31) := '2020444F574E4C4F41443A2022446F776E6C6F6164222C0A2020202020202020504C41593A2022506C6179222C0A2020202020202020484944455F504C415945523A20224869646520506C61796572222C0A202020202020202044454C4554453A202244';
wwv_flow_imp.g_varchar2_table(32) := '656C657465222C0A202020202020202052454144593A20225265616479222C0A20202020202020205245434F5244494E473A20225265636F7264696E67222C0A20202020202020205041555345443A2022506175736564222C0A20202020202020205245';
wwv_flow_imp.g_varchar2_table(33) := '564945573A2022526576696577222C0A202020202020202055504C4F4144494E473A2022536176696E67222C0A20202020202020205354415254494E473A20225374617274696E67222C0A202020202020202046494E495348494E473A202246696E6973';
wwv_flow_imp.g_varchar2_table(34) := '68696E67222C0A202020202020202053415645443A20225361766564222C0A202020202020202050454E44494E473A20224174746163686564222C0A20202020202020205452414E5343524942494E475F5345525645523A20225472616E736372696269';
wwv_flow_imp.g_varchar2_table(35) := '6E67222C0A20202020202020205245564945575F5449544C453A20224C697374656E20746F206F7220776174636820796F7572207265636F7264696E67206265666F726520796F75207573652069742E222C0A202020202020202055504C4F41445F5052';
wwv_flow_imp.g_varchar2_table(36) := '4F47524553533A2022536176696E6720253025222C0A20202020202020204C494D49545F48494E543A2022557020746F202530222C0A20202020202020204C494D49545F48494E545F54494D453A2022557020746F202530206F72202531222C0A202020';
wwv_flow_imp.g_varchar2_table(37) := '202020202043415041434954593A202261626F75742025302061742074686973207175616C697479222C0A20202020202020204D455445523A202261626F7574202530206C65667420C2B7202531206F66202532222C0A20202020202020204F463A2022';
wwv_flow_imp.g_varchar2_table(38) := '2530206F66202531222C0A20202020202020205741524E5F53495A453A2022416C6D6F737420617420746865206C696D69743A202530206F6620253120757365642E205265636F7264696E672073746F7073206175746F6D61746963616C6C7920617420';
wwv_flow_imp.g_varchar2_table(39) := '25312E222C0A20202020202020205741524E5F54494D453A2022416C6D6F737420617420746865206C696D69743A202530206F662025312E205265636F7264696E672073746F7073206175746F6D61746963616C6C792061742025312E222C0A20202020';
wwv_flow_imp.g_varchar2_table(40) := '2020202053544F505045445F53495A453A20225265636F7264696E672073746F707065643A20746865206D6178696D756D2073697A65206F662025302077617320726561636865642E222C0A202020202020202053544F505045445F54494D453A202252';
wwv_flow_imp.g_varchar2_table(41) := '65636F7264696E672073746F707065643A20746865206D6178696D756D206C656E677468206F662025302077617320726561636865642E222C0A20202020202020204445564943455F454E4445443A2022546865206D6963726F70686F6E65206F722063';
wwv_flow_imp.g_varchar2_table(42) := '616D657261207761732073746F707065642028666F72206578616D706C6520627920612063616C6C206F72207468652073637265656E206C6F636B696E67292E205768617420776173207265636F7264656420736F20666172206973206B6570742E222C';
wwv_flow_imp.g_varchar2_table(43) := '0A20202020202020204D41585F434F554E543A2022546865206D6178696D756D206F6620253020686173206265656E20726561636865642E2044656C657465206F6E6520746F2061646420616E6F746865722E222C0A20202020202020204D41585F434F';
wwv_flow_imp.g_varchar2_table(44) := '554E545F4F4E453A20224F6E652068617320616C7265616479206265656E2061646465642E2044656C65746520697420746F2061646420616E6F746865722E222C0A202020202020202046494C455F544F4F5F4C415247453A2022546869732066696C65';
wwv_flow_imp.g_varchar2_table(45) := '2069732025302C206D6F7265207468616E20746865206D6178696D756D206F662025312E222C0A2020202020202020544F4F5F4C415247455F4B4545503A202254686973207265636F7264696E672063616D65206F75742061742025302C206D6F726520';
wwv_flow_imp.g_varchar2_table(46) := '7468616E2074686520253120616C6C6F7765642C20736F2069742063616E6E6F74206265207573656420686572652E20446F776E6C6F616420697420736F206974206973206E6F74206C6F73742C206F72207265636F726420612073686F72746572206F';
wwv_flow_imp.g_varchar2_table(47) := '6E652E222C0A202020202020202046494C455F57524F4E475F545950453A202243686F6F736520612066696C65206F6620616E20616C6C6F776564206B696E642E222C0A20202020202020204E4F5F5045524D495353494F4E3A2022416C6C6F77206163';
wwv_flow_imp.g_varchar2_table(48) := '6365737320746F20746865206D6963726F70686F6E65206F722063616D65726120696E20796F75722062726F777365722073657474696E67732C207468656E2074727920616761696E2E222C0A20202020202020204E4F5F4445564943453A20224E6F20';
wwv_flow_imp.g_varchar2_table(49) := '6D6963726F70686F6E65206F722063616D6572612077617320666F756E642E222C0A20202020202020204E4F545F535550504F525445443A20225468652063616D65726120616E64206D6963726F70686F6E6520617265206E6F7420617661696C61626C';
wwv_flow_imp.g_varchar2_table(50) := '6520686572653A2074686579206E6565642061207365637572652028687474707329207061676520616E6420612063757272656E742062726F777365722E222C0A2020202020202020425553593A202246696E6973682066697273743A20757365206F72';
wwv_flow_imp.g_varchar2_table(51) := '206469736361726420746865207265636F7264696E67206F722070686F746F2E222C0A2020202020202020434F4E4649524D5F44454C4554453A202244656C65746520746869733F222C0A2020202020202020434F4E4649524D5F444953434152443A20';
wwv_flow_imp.g_varchar2_table(52) := '224469736361726420746869733F222C0A202020202020202055504C4F41445F4641494C45443A20225468697320636F756C64206E6F742062652073617665642E202530204974206973207374696C6C2068657265202D2074727920616761696E2C206F';
wwv_flow_imp.g_varchar2_table(53) := '7220646F776E6C6F61642069742E222C0A20202020202020204E4554574F524B3A202254686520636F6E6E656374696F6E20776173206C6F73742E222C0A202020202020202053455353494F4E5F454E4445443A2022596F75722073657373696F6E2068';
wwv_flow_imp.g_varchar2_table(54) := '617320656E6465642C20736F207468697320636F756C64206E6F742062652073617665642E20446F776E6C6F6164206974206E6F7720736F206974206973206E6F74206C6F73742C207468656E207369676E20696E20616761696E2E222C0A2020202020';
wwv_flow_imp.g_varchar2_table(55) := '2020205245434F56455245443A2022536F6D657468696E6720796F7520686164206E6F7420757365642079657420776173207265636F76657265642E20557365206974206F7220646973636172642069742E222C0A2020202020202020504C41595F4641';
wwv_flow_imp.g_varchar2_table(56) := '494C45443A2022546865207265636F7264696E6720636F756C64206E6F7420626520706C617965642E202530222C0A20202020202020205452414E5343524950543A20225472616E736372697074222C0A20202020202020205452414E5343524950545F';
wwv_flow_imp.g_varchar2_table(57) := '4C414E47554147453A20225472616E736372697074696F6E206C616E6775616765222C0A20202020202020205452414E5343524950545F504C414345484F4C4445523A20224E6F7468696E6720776173207265636F676E69736564202D20747970652077';
wwv_flow_imp.g_varchar2_table(58) := '6861742077617320736169642C206F72206C6561766520697420656D7074792E222C0A20202020202020205452414E5343524942494E473A20224C697374656E696E672E2E2E222C0A20202020202020205354545F554E535550504F525445443A202254';
wwv_flow_imp.g_varchar2_table(59) := '6869732062726F777365722063616E6E6F74207472616E7363726962652E20596F752063616E2074797065207468652074657874206166746572207265636F7264696E672E222C0A20202020202020205354545F4641494C45443A20224C697665207472';
wwv_flow_imp.g_varchar2_table(60) := '616E736372697074696F6E2073746F7070656420282530292E20596F752063616E2074797065206F7220636F7272656374207468652074657874206166746572207265636F7264696E672E222C0A20202020202020204B4559533A202250203D20706175';
wwv_flow_imp.g_varchar2_table(61) := '7365202F20726573756D652C2053203D2073746F70222C0A20202020202020204E4F5F534F554E443A20224E6F20736F756E64206973207265616368696E6720746865207265636F7264696E672E20436865636B20746865206D6963726F70686F6E6520';
wwv_flow_imp.g_varchar2_table(62) := '2D206966206865616470686F6E6573206F7220416972506F64732061726520636F6E6E65637465642C2074727920616761696E20776974686F7574207468656D2E220A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(63) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2068656C706572730A2020202066756E6374696F6E20747874286B657929207B0A20202020202020207661722066756C6C203D20';
wwv_flow_imp.g_varchar2_table(64) := '224D45444941504C55532E22202B206B65792C0A20202020202020202020202074203D20617065782E6C616E672E6765744D6573736167652866756C6C292C0A20202020202020202020202061726773203D2041727261792E70726F746F747970652E73';
wwv_flow_imp.g_varchar2_table(65) := '6C6963652E63616C6C28617267756D656E74732C2031293B0A2020202020202020696620282174207C7C2074203D3D3D2066756C6C29207B2074203D20544558545B6B65795D207C7C206B65793B207D0A202020202020202072657475726E20742E7265';
wwv_flow_imp.g_varchar2_table(66) := '706C616365282F25285C64292F672C2066756E6374696F6E20286D2C206E29207B2072657475726E20617267735B6E5D20213D3D20756E646566696E6564203F20617267735B6E5D203A206D3B207D293B0A202020207D0A0A2020202066756E6374696F';
wwv_flow_imp.g_varchar2_table(67) := '6E20656C287461672C20636C732C2061747472732C206B69647329207B0A20202020202020207661722065203D20646F63756D656E742E637265617465456C656D656E7428746167293B0A202020202020202069662028636C7329207B20652E636C6173';
wwv_flow_imp.g_varchar2_table(68) := '734E616D65203D20636C733B207D0A202020202020202069662028617474727329207B0A2020202020202020202020204F626A6563742E6B657973286174747273292E666F72456163682866756E6374696F6E20286B29207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(69) := '2020202020206966202861747472735B6B5D203D3D3D206E756C6C207C7C2061747472735B6B5D203D3D3D20756E646566696E6564207C7C2061747472735B6B5D203D3D3D2066616C736529207B2072657475726E3B207D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(70) := '2020202020696620286B203D3D3D2022746578742229207B20652E74657874436F6E74656E74203D2061747472735B6B5D3B207D20656C7365207B20652E736574417474726962757465286B2C2061747472735B6B5D203D3D3D2074727565203F202222';
wwv_flow_imp.g_varchar2_table(71) := '203A2061747472735B6B5D293B207D0A2020202020202020202020207D293B0A20202020202020207D0A2020202020202020286B696473207C7C205B5D292E666F72456163682866756E6374696F6E20286B29207B20696620286B29207B20652E617070';
wwv_flow_imp.g_varchar2_table(72) := '656E644368696C64286B293B207D207D293B0A202020202020202072657475726E20653B0A202020207D0A0A2020202066756E6374696F6E20666149636F6E286E616D6529207B2072657475726E20656C28227370616E222C2022742D49636F6E206661';
wwv_flow_imp.g_varchar2_table(73) := '2022202B206E616D652C207B2022617269612D68696464656E223A20227472756522207D293B207D0A0A202020202F2F2069636F6E2D6F6E6C7920556E6976657273616C205468656D6520627574746F6E20286C69737420726F7773290A202020206675';
wwv_flow_imp.g_varchar2_table(74) := '6E6374696F6E2069636F6E427574746F6E28636C732C2069636F6E4E616D652C206C6162656C29207B0A202020202020202072657475726E20656C2822627574746F6E222C2022742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D4275';
wwv_flow_imp.g_varchar2_table(75) := '74746F6E2D2D6E6F554920742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D2D69636F6E2022202B20636C732C0A2020202020202020202020202020202020207B20747970653A2022627574746F6E222C207469746C653A206C616265';
wwv_flow_imp.g_varchar2_table(76) := '6C2C2022617269612D6C6162656C223A206C6162656C207D2C205B666149636F6E2869636F6E4E616D65295D293B0A202020207D0A0A202020202F2F207265636F7264657220636F6E74726F6C3A20612070696C6C20286F722C20776974682042757474';
wwv_flow_imp.g_varchar2_table(77) := '6F6E205374796C65203D205468656D652C206120556E6976657273616C205468656D6520627574746F6E292077697468206120647261776E0A202020202F2F2069636F6E20287265632C2070617573652C2073746F702C20706C617929206F7220612046';
wwv_flow_imp.g_varchar2_table(78) := '6F6E7420415045582069636F6E202866612D2E2E2E290A20202020766172205448454D455F434C415353203D207B20226D706C75732D62746E2D2D726563223A2022742D427574746F6E2D2D64616E676572222C20226D706C75732D62746E2D2D73746F';
wwv_flow_imp.g_varchar2_table(79) := '70223A2022742D427574746F6E2D2D64616E676572222C20226D706C75732D62746E2D2D7072696D617279223A2022742D427574746F6E2D2D686F74222C0A202020202020202020202020202020202020202020202020226D706C75732D62746E2D2D67';
wwv_flow_imp.g_varchar2_table(80) := '686F7374223A2022742D427574746F6E2D2D6E6F5549222C20226D706C75732D62746E2D2D69636F6E223A2022742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D2D69636F6E22207D3B0A2020202066756E6374696F6E207365744374';
wwv_flow_imp.g_varchar2_table(81) := '6C28622C2069636F6E4E616D652C206C6162656C29207B0A20202020202020207661722069203D20622E717565727953656C6563746F7228222E6D706C75732D6922292C206C203D20622E717565727953656C6563746F7228222E6D706C75732D62746E';
wwv_flow_imp.g_varchar2_table(82) := '2D6C6162656C22293B0A2020202020202020692E636C6173734E616D65203D20226D706C75732D692022202B202869636F6E4E616D652E696E6465784F66282266612D2229203D3D3D2030203F202266612022202B2069636F6E4E616D65203A20226D70';
wwv_flow_imp.g_varchar2_table(83) := '6C75732D692D2D22202B2069636F6E4E616D6529202B2028622E6D706C75735468656D65203F202220742D49636F6E20742D49636F6E2D2D6C65667422203A202222293B0A20202020202020206C2E74657874436F6E74656E74203D206C6162656C3B0A';
wwv_flow_imp.g_varchar2_table(84) := '2020202020202020622E7469746C65203D20622E6D706C75734B6579203F206C6162656C202B2022202822202B20622E6D706C75734B6579202B20222922203A206C6162656C3B0A202020202020202069662028622E6D706C757349636F6E4F6E6C7929';
wwv_flow_imp.g_varchar2_table(85) := '207B20622E7365744174747269627574652822617269612D6C6162656C222C206C6162656C293B207D0A202020207D0A2020202066756E6374696F6E2063746C28636C732C2069636F6E4E616D652C206C6162656C2C2069636F6E4F6E6C792C20746865';
wwv_flow_imp.g_varchar2_table(86) := '6D6529207B0A2020202020202020766172206D6F6473203D202828636C73207C7C20222229202B202869636F6E4F6E6C79203F2022206D706C75732D62746E2D2D69636F6E22203A20222229292E73706C697428222022292E66696C74657228426F6F6C';
wwv_flow_imp.g_varchar2_table(87) := '65616E292C0A2020202020202020202020206B6C617373203D20226D706C75732D62746E2022202B206D6F64732E6A6F696E28222022293B0A2020202020202020696620287468656D6529207B0A2020202020202020202020202F2F20556E6976657273';
wwv_flow_imp.g_varchar2_table(88) := '616C205468656D6520627574746F6E3A207468652070696C6C206D6F6469666965727320617265207377617070656420666F72207468656D65206F6E65732C20746865206D706C75732D622D2A206E616D657320737461790A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(89) := '206B6C617373203D20226D706C75732D62746E2D2D7468656D6520742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D427574746F6E2D2D69636F6E4C6566742022202B0A20202020202020202020202020202020202020206D6F64732E';
wwv_flow_imp.g_varchar2_table(90) := '6D61702866756E6374696F6E20286D29207B2072657475726E205448454D455F434C4153535B6D5D207C7C20286D2E696E6465784F6628226D706C75732D62746E2D2D2229203D3D3D2030203F202222203A206D293B207D292E6A6F696E28222022293B';
wwv_flow_imp.g_varchar2_table(91) := '0A20202020202020207D0A20202020202020207661722062203D20656C2822627574746F6E222C206B6C6173732C207B20747970653A2022627574746F6E22207D2C0A202020202020202020202020202020202020205B656C28227370616E222C20226D';
wwv_flow_imp.g_varchar2_table(92) := '706C75732D69222C207B2022617269612D68696464656E223A20227472756522207D292C20656C28227370616E222C20226D706C75732D62746E2D6C6162656C22202B20287468656D65203F202220742D427574746F6E2D6C6162656C22203A20222229';
wwv_flow_imp.g_varchar2_table(93) := '295D293B0A2020202020202020622E6D706C75735468656D65203D2021217468656D653B0A2020202020202020622E6D706C757349636F6E4F6E6C79203D20212169636F6E4F6E6C793B0A202020202020202073657443746C28622C2069636F6E4E616D';
wwv_flow_imp.g_varchar2_table(94) := '652C206C6162656C293B0A202020202020202072657475726E20623B0A202020207D0A0A2020202066756E6374696F6E2073686F7728652C206F6E29207B20696620286529207B20652E68696464656E203D20216F6E3B207D207D0A0A2020202066756E';
wwv_flow_imp.g_varchar2_table(95) := '6374696F6E20666D744279746573286229207B0A20202020202020206966202862203C203130323429207B2072657475726E204D6174682E726F756E64286229202B20222042223B207D0A20202020202020206966202862203C20313034383537362920';
wwv_flow_imp.g_varchar2_table(96) := '7B2072657475726E204D6174682E726F756E642862202F203130323429202B2022204B42223B207D0A2020202020202020766172206D62203D2062202F20313034383537363B0A202020202020202072657475726E20286D62203C203130203F206D622E';
wwv_flow_imp.g_varchar2_table(97) := '746F4669786564283129203A204D6174682E726F756E64286D622929202B2022204D42223B0A202020207D0A0A2020202066756E6374696F6E20666D7454696D652873656329207B0A2020202020202020736563203D204D6174682E6D617828302C204D';
wwv_flow_imp.g_varchar2_table(98) := '6174682E726F756E6428736563207C7C203029293B0A20202020202020207661722068203D204D6174682E666C6F6F7228736563202F2033363030292C206D203D204D6174682E666C6F6F7228287365632025203336303029202F203630292C2073203D';
wwv_flow_imp.g_varchar2_table(99) := '2073656320252036303B0A202020202020202072657475726E202868203F2068202B20223A22202B20537472696E67286D292E706164537461727428322C2022302229203A206D29202B20223A22202B20537472696E672873292E706164537461727428';
wwv_flow_imp.g_varchar2_table(100) := '322C20223022293B0A202020207D0A0A2020202066756E6374696F6E20666D745370616E2873656329207B0A202020202020202069662028736563203E3D203336303029207B2072657475726E2028736563202F2033363030292E746F46697865642831';
wwv_flow_imp.g_varchar2_table(101) := '292E7265706C616365282F5C2E30242F2C20222229202B20222068223B207D0A202020202020202069662028736563203E3D2031323029207B2072657475726E204D6174682E726F756E6428736563202F20363029202B2022206D696E223B207D0A2020';
wwv_flow_imp.g_varchar2_table(102) := '20202020202072657475726E20666D7454696D6528736563293B0A202020207D0A0A2020202066756E6374696F6E20746F6B656E2829207B0A20202020202020207661722061203D206E65772055696E74384172726179283136292C2073203D2022223B';
wwv_flow_imp.g_varchar2_table(103) := '0A202020202020202077696E646F772E63727970746F2E67657452616E646F6D56616C7565732861293B0A2020202020202020612E666F72456163682866756E6374696F6E20286E29207B2073202B3D206E2E746F537472696E67283136292E70616453';
wwv_flow_imp.g_varchar2_table(104) := '7461727428322C20223022293B207D293B0A202020202020202072657475726E20733B0A202020207D0A0A2020202066756E6374696F6E20657874466F72286D696D6529207B0A20202020202020206D696D65203D20286D696D65207C7C202222292E73';
wwv_flow_imp.g_varchar2_table(105) := '706C697428223B22295B305D3B0A2020202020202020766172206D6170203D207B2022696D6167652F6A706567223A20226A7067222C2022696D6167652F706E67223A2022706E67222C2022696D6167652F77656270223A202277656270222C2022696D';
wwv_flow_imp.g_varchar2_table(106) := '6167652F676966223A2022676966222C2022696D6167652F68656963223A202268656963222C0A202020202020202020202020202020202020202022617564696F2F7765626D223A20227765626D222C2022766964656F2F7765626D223A20227765626D';
wwv_flow_imp.g_varchar2_table(107) := '222C2022617564696F2F6D7034223A20226D3461222C2022766964656F2F6D7034223A20226D7034222C2022617564696F2F6F6767223A20226F6767222C0A202020202020202020202020202020202020202022617564696F2F6D706567223A20226D70';
wwv_flow_imp.g_varchar2_table(108) := '33222C2022617564696F2F776176223A2022776176222C2022617564696F2F782D776176223A2022776176222C2022766964656F2F717569636B74696D65223A20226D6F76222C2022617564696F2F616163223A2022616163222C0A2020202020202020';
wwv_flow_imp.g_varchar2_table(109) := '20202020202020202020202022766964656F2F782D6D6174726F736B61223A20226D6B76222C2022617564696F2F782D6D3461223A20226D3461222C2022766964656F2F33677070223A2022336770222C2022617564696F2F33677070223A2022336770';
wwv_flow_imp.g_varchar2_table(110) := '22207D3B0A202020202020202072657475726E206D61705B6D696D655D207C7C20286D696D652E73706C697428222F22295B315D207C7C202262696E22292E7265706C616365282F5B5E612D7A302D395D2F672C202222293B0A202020207D0A0A202020';
wwv_flow_imp.g_varchar2_table(111) := '202F2F20576869636820636F6E7461696E657220746F2061736B20666F722E204155544F3A204D5034202D20766964656F204D50342028482E323634202F20414143292C20617564696F204D3441202841414329202D207768696368206F70656E732065';
wwv_flow_imp.g_varchar2_table(112) := '7665727977686572650A202020202F2F20286950686F6E652C204D61632C2057696E646F7773204D6564696120506C617965722C20416E64726F6964293B2046697265666F782C2077686963682063616E6E6F74207772697465204D50342C207265636F';
wwv_flow_imp.g_varchar2_table(113) := '726473205765624D2E0A202020202F2F205745424D3A205765624D202F204F7075732C20736D616C6C6573742C206275742073617665642066696C657320646F206E6F74206F70656E206F6E206950686F6E6573206F7220696E2057696E646F7773204D';
wwv_flow_imp.g_varchar2_table(114) := '6564696120506C617965722E0A202020202F2F204E6F2062726F777365722063616E207265636F7264204D50332E2045766572792066696C65206973207265706169726564206166746572207265636F7264696E6720286669784D7034202F2066697857';
wwv_flow_imp.g_varchar2_table(115) := '65626D292C20736F206974206861732061206475726174696F6E0A202020202F2F20616E642061207365656B20696E64657820696E20657665727920706C617965722E0A2020202066756E6374696F6E207069636B4D696D65286B696E642C20666F726D';
wwv_flow_imp.g_varchar2_table(116) := '617429207B0A2020202020202020696620282177696E646F772E4D656469615265636F72646572207C7C20214D656469615265636F726465722E697354797065537570706F7274656429207B2072657475726E2022223B207D0A20202020202020207661';
wwv_flow_imp.g_varchar2_table(117) := '72206C69737473203D207B0A202020202020202020202020617564696F3A207B205745424D3A205B22617564696F2F7765626D3B636F646563733D6F707573222C2022617564696F2F7765626D225D2C204D50343A205B22617564696F2F6D70343B636F';
wwv_flow_imp.g_varchar2_table(118) := '646563733D6D7034612E34302E32222C2022617564696F2F6D7034225D2C204F47473A205B22617564696F2F6F67673B636F646563733D6F707573225D207D2C0A202020202020202020202020766964656F3A207B205745424D3A205B22766964656F2F';
wwv_flow_imp.g_varchar2_table(119) := '7765626D3B636F646563733D7670382C6F707573222C2022766964656F2F7765626D3B636F646563733D7670392C6F707573222C2022766964656F2F7765626D225D2C0A2020202020202020202020202020202020202020204D50343A205B2276696465';
wwv_flow_imp.g_varchar2_table(120) := '6F2F6D70343B636F646563733D617663312E3432453031452C6D7034612E34302E32222C2022766964656F2F6D70343B636F646563733D617663312C6D703461222C2022766964656F2F6D7034225D207D0A20202020202020207D3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(121) := '20766172206F72646572203D20666F726D6174203D3D3D20225745424D22203F205B225745424D222C20224F4747222C20224D5034225D203A205B224D5034222C20225745424D222C20224F4747225D2C0A202020202020202020202020666F756E6420';
wwv_flow_imp.g_varchar2_table(122) := '3D2022223B0A20202020202020206F726465722E736F6D652866756E6374696F6E20286629207B0A20202020202020202020202072657475726E20286C697374735B6B696E645D5B665D207C7C205B5D292E736F6D652866756E6374696F6E20286D2920';
wwv_flow_imp.g_varchar2_table(123) := '7B0A20202020202020202020202020202020696620284D656469615265636F726465722E697354797065537570706F72746564286D2929207B20666F756E64203D206D3B2072657475726E20747275653B207D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(124) := '72657475726E2066616C73653B0A2020202020202020202020207D293B0A20202020202020207D293B0A202020202020202072657475726E20666F756E643B0A202020207D0A0A202020202F2F205365656B20746F2074686520656E64206F6E63652077';
wwv_flow_imp.g_varchar2_table(125) := '68656E2074686520706C6179657220646F6573206E6F74206B6E6F7720746865206475726174696F6E207965740A2020202066756E6374696F6E206669784475726174696F6E286D6564696129207B0A20202020202020206D656469612E616464457665';
wwv_flow_imp.g_varchar2_table(126) := '6E744C697374656E657228226C6F616465646D65746164617461222C2066756E6374696F6E202829207B0A202020202020202020202020696620286D656469612E6475726174696F6E203D3D3D20496E66696E697479207C7C2069734E614E286D656469';
wwv_flow_imp.g_varchar2_table(127) := '612E6475726174696F6E2929207B0A20202020202020202020202020202020766172206261636B203D2066756E6374696F6E202829207B206D656469612E72656D6F76654576656E744C697374656E6572282274696D65757064617465222C206261636B';
wwv_flow_imp.g_varchar2_table(128) := '293B206D656469612E63757272656E7454696D65203D20303B207D3B0A202020202020202020202020202020206D656469612E6164644576656E744C697374656E6572282274696D65757064617465222C206261636B293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(129) := '20202020206D656469612E63757272656E7454696D65203D2031653130313B0A2020202020202020202020207D0A20202020202020207D2C207B206F6E63653A2074727565207D293B0A202020207D0A0A2020202066756E6374696F6E20726561644261';
wwv_flow_imp.g_varchar2_table(130) := '7365363428626C6F6229207B0A202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20287265736F6C76652C2072656A65637429207B0A2020202020202020202020207661722072203D206E65772046696C65526561';
wwv_flow_imp.g_varchar2_table(131) := '64657228293B0A202020202020202020202020722E6F6E6C6F6164203D2066756E6374696F6E202829207B207265736F6C766528537472696E6728722E726573756C74292E73706C697428222C22295B315D207C7C202222293B207D3B0A202020202020';
wwv_flow_imp.g_varchar2_table(132) := '202020202020722E6F6E6572726F72203D2066756E6374696F6E202829207B2072656A65637428722E6572726F72293B207D3B0A202020202020202020202020722E7265616441734461746155524C28626C6F62293B0A20202020202020207D293B0A20';
wwv_flow_imp.g_varchar2_table(133) := '2020207D0A0A2020202066756E6374696F6E206D656469614475726174696F6E28626C6F6229207B0A202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20287265736F6C766529207B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(134) := '20766172206B696E64203D2028626C6F622E74797065207C7C202222292E696E6465784F662822766964656F2229203D3D3D2030203F2022766964656F22203A2022617564696F222C0A202020202020202020202020202020206D203D20646F63756D65';
wwv_flow_imp.g_varchar2_table(135) := '6E742E637265617465456C656D656E74286B696E64292C2075726C203D2055524C2E6372656174654F626A65637455524C28626C6F62292C20646F6E65203D2066616C73652C0A2020202020202020202020202020202066696E697368203D2066756E63';
wwv_flow_imp.g_varchar2_table(136) := '74696F6E20286429207B206966202821646F6E6529207B20646F6E65203D20747275653B2055524C2E7265766F6B654F626A65637455524C2875726C293B207265736F6C766528697346696E697465286429203F2064203A2030293B207D207D3B0A2020';
wwv_flow_imp.g_varchar2_table(137) := '202020202020202020206D2E7072656C6F6164203D20226D65746164617461223B0A2020202020202020202020206D2E6F6E6C6F616465646D65746164617461203D2066756E6374696F6E202829207B2066696E697368286D2E6475726174696F6E293B';
wwv_flow_imp.g_varchar2_table(138) := '207D3B0A2020202020202020202020206D2E6F6E6572726F72203D2066756E6374696F6E202829207B2066696E6973682830293B207D3B0A20202020202020202020202073657454696D656F75742866756E6374696F6E202829207B2066696E69736828';
wwv_flow_imp.g_varchar2_table(139) := '30293B207D2C2034303030293B0A2020202020202020202020206D2E737263203D2075726C3B0A20202020202020207D293B0A202020207D0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(140) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D206472616674732028496E64657865644442290A202020202F2F2041207265636F7264696E67207468617420697320726576696577656420627574206E6F74207573656420';
wwv_flow_imp.g_varchar2_table(141) := '7965742C206F722074686174206661696C656420746F2075706C6F61642C206973206B65707420696E207468652062726F777365722C0A202020202F2F20736F20612072656C6F61642C2061206372617368206F7220616E206578706972656420736573';
wwv_flow_imp.g_varchar2_table(142) := '73696F6E20646F6573206E6F74206C6F73652069742E0A2020202076617220647261667473203D202866756E6374696F6E202829207B0A202020202020202076617220646270203D206E756C6C3B0A202020202020202066756E6374696F6E2064622829';
wwv_flow_imp.g_varchar2_table(143) := '207B0A202020202020202020202020696620282164627029207B0A20202020202020202020202020202020646270203D206E65772050726F6D6973652866756E6374696F6E20287265736F6C76652C2072656A65637429207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(144) := '20202020202020202020696620282177696E646F772E696E6465786564444229207B2072656A656374286E6577204572726F7228226E6F20496E646578656444422229293B2072657475726E3B207D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(145) := '76617220726571203D20696E646578656444422E6F70656E28226D65646961506C7573447261667473222C2031293B0A20202020202020202020202020202020202020207265712E6F6E757067726164656E6565646564203D2066756E6374696F6E2028';
wwv_flow_imp.g_varchar2_table(146) := '29207B207265712E726573756C742E6372656174654F626A65637453746F7265282264726166747322293B207D3B0A20202020202020202020202020202020202020207265712E6F6E73756363657373203D2066756E6374696F6E202829207B20726573';
wwv_flow_imp.g_varchar2_table(147) := '6F6C7665287265712E726573756C74293B207D3B0A20202020202020202020202020202020202020207265712E6F6E6572726F72203D2066756E6374696F6E202829207B2072656A656374287265712E6572726F72293B207D3B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(148) := '202020202020207D293B0A2020202020202020202020207D0A20202020202020202020202072657475726E206462703B0A20202020202020207D0A202020202020202066756E6374696F6E2072756E286D6F64652C20666E29207B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(149) := '2020202072657475726E20646228292E7468656E2866756E6374696F6E20286429207B0A2020202020202020202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20287265736F6C76652C2072656A65637429207B0A';
wwv_flow_imp.g_varchar2_table(150) := '2020202020202020202020202020202020202020766172207478203D20642E7472616E73616374696F6E2822647261667473222C206D6F6465292C20726571203D20666E2874782E6F626A65637453746F726528226472616674732229293B0A20202020';
wwv_flow_imp.g_varchar2_table(151) := '2020202020202020202020202020202074782E6F6E636F6D706C657465203D2066756E6374696F6E202829207B207265736F6C766528726571202626207265712E726573756C74293B207D3B0A202020202020202020202020202020202020202074782E';
wwv_flow_imp.g_varchar2_table(152) := '6F6E6572726F72203D2074782E6F6E61626F7274203D2066756E6374696F6E202829207B2072656A6563742874782E6572726F72293B207D3B0A202020202020202020202020202020207D293B0A2020202020202020202020207D292E63617463682866';
wwv_flow_imp.g_varchar2_table(153) := '756E6374696F6E202829207B2072657475726E206E756C6C3B207D293B0A20202020202020207D0A202020202020202072657475726E207B0A2020202020202020202020206765743A2066756E6374696F6E20286B657929207B2072657475726E207275';
wwv_flow_imp.g_varchar2_table(154) := '6E2822726561646F6E6C79222C2066756E6374696F6E20287329207B2072657475726E20732E676574286B6579293B207D293B207D2C0A2020202020202020202020207075743A2066756E6374696F6E20286B65792C2076616C29207B2072657475726E';
wwv_flow_imp.g_varchar2_table(155) := '2072756E2822726561647772697465222C2066756E6374696F6E20287329207B2072657475726E20732E7075742876616C2C206B6579293B207D293B207D2C0A20202020202020202020202064656C3A2066756E6374696F6E20286B657929207B207265';
wwv_flow_imp.g_varchar2_table(156) := '7475726E2072756E2822726561647772697465222C2066756E6374696F6E20287329207B2072657475726E20732E64656C657465286B6579293B207D293B207D0A20202020202020207D3B0A202020207D2928293B0A0A202020202F2F202D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(157) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D205765624D207265706169720A202020202F2F204D656469615265636F7264657220777269746573';
wwv_flow_imp.g_varchar2_table(158) := '20226C69766522205765624D3A206E6F204475726174696F6E2C20636C757374657273206F6620756E6B6E6F776E2073697A6520616E64206E6F20437565732C20736F20706C6179657273207375636820617320564C430A202020202F2F2063616E6E6F';
wwv_flow_imp.g_varchar2_table(159) := '74207365656B20616E6420736F6D652077696C6C206E6F74206F70656E207468652066696C652E2054686973207265777269746573206974206173206120726567756C61722066696C653A204475726174696F6E20696E20496E666F2C2073697A65640A';
wwv_flow_imp.g_varchar2_table(160) := '202020202F2F20636C7573746572732C2061205365656B4865616420616E642061204375657320696E64657820286F6E206B65796672616D6520636C757374657273292E20416E797468696E6720756E65787065637465642072657475726E7320746865';
wwv_flow_imp.g_varchar2_table(161) := '206F726967696E616C2E0A202020207661722045424D4C203D207B0A20202020202020204845414445523A20307831413435444641332C205345474D454E543A20307831383533383036372C205345454B484541443A20307831313444394237342C2053';
wwv_flow_imp.g_varchar2_table(162) := '45454B3A203078344442422C205345454B49443A203078353341422C205345454B504F533A203078353341432C0A2020202020202020494E464F3A20307831353439413936362C205343414C453A2030783241443742312C204455524154494F4E3A2030';
wwv_flow_imp.g_varchar2_table(163) := '78343438392C20545241434B533A20307831363534414536422C20545241434B3A20307841452C20545241434B4E4F3A20307844372C20545241434B545950453A20307838332C0A2020202020202020434C55535445523A20307831463433423637352C';
wwv_flow_imp.g_varchar2_table(164) := '2054494D45434F44453A20307845372C2053494D504C45424C4F434B3A20307841332C20424C4F434B47524F55503A20307841302C20424C4F434B3A20307841312C20564F49443A20307845432C0A2020202020202020435545533A2030783143353342';
wwv_flow_imp.g_varchar2_table(165) := '4236422C20435545504F494E543A20307842422C2043554554494D453A20307842332C20435545504F533A20307842372C20435545545241434B3A20307846372C20435545434C55535445523A20307846310A202020207D3B0A20202020766172204C45';
wwv_flow_imp.g_varchar2_table(166) := '56454C31203D205B45424D4C2E5345454B484541442C2045424D4C2E494E464F2C2045424D4C2E545241434B532C2045424D4C2E434C55535445522C2045424D4C2E435545532C20307831323534433336372C20307831303433413737302C2030783139';
wwv_flow_imp.g_varchar2_table(167) := '3431413436395D3B0A0A2020202066756E6374696F6E207265616456696E7428622C20702C206973496429207B0A2020202020202020766172206669727374203D20625B705D2C206C656E203D20312C206D61736B203D20307838303B0A202020202020';
wwv_flow_imp.g_varchar2_table(168) := '20207768696C6520286C656E203C3D203820262620212866697273742026206D61736B2929207B206C656E2B2B3B206D61736B203E3E3D20313B207D0A2020202020202020696620286C656E203E203829207B207468726F77206E6577204572726F7228';
wwv_flow_imp.g_varchar2_table(169) := '226261642076696E7422293B207D0A20202020202020207661722076203D2069734964203F206669727374203A206669727374202620286D61736B202D2031292C20616C6C4F6E6573203D20286669727374202620286D61736B202D20312929203D3D3D';
wwv_flow_imp.g_varchar2_table(170) := '206D61736B202D20313B0A2020202020202020666F7220287661722069203D20313B2069203C206C656E3B20692B2B29207B2076203D2076202A20323536202B20625B70202B20695D3B20616C6C4F6E6573203D20616C6C4F6E657320262620625B7020';
wwv_flow_imp.g_varchar2_table(171) := '2B20695D203D3D3D203235353B207D0A202020202020202072657475726E207B20763A20762C206C656E3A206C656E2C20756E6B6E6F776E3A20216973496420262620616C6C4F6E6573207D3B0A202020207D0A2020202066756E6374696F6E20726561';
wwv_flow_imp.g_varchar2_table(172) := '6455696E7428622C20702C206E29207B207661722076203D20303B20666F7220287661722069203D20303B2069203C206E3B20692B2B29207B2076203D2076202A20323536202B20625B70202B20695D3B207D2072657475726E20763B207D0A20202020';
wwv_flow_imp.g_varchar2_table(173) := '66756E6374696F6E206964427974657328696429207B207661722061203D205B5D3B207768696C6520286964203E203029207B20612E756E7368696674286964202620323535293B206964203D204D6174682E666C6F6F72286964202F20323536293B20';
wwv_flow_imp.g_varchar2_table(174) := '7D2072657475726E206E65772055696E743841727261792861293B207D0A2020202066756E6374696F6E2073697A6538286E29207B207661722061203D206E65772055696E743841727261792838293B20615B305D203D20313B20666F72202876617220';
wwv_flow_imp.g_varchar2_table(175) := '69203D20373B2069203E3D20313B20692D2D29207B20615B695D203D206E2025203235363B206E203D204D6174682E666C6F6F72286E202F20323536293B207D2072657475726E20613B207D0A2020202066756E6374696F6E2075696E74427974657328';
wwv_flow_imp.g_varchar2_table(176) := '6E2C206C656E29207B207661722061203D206E65772055696E74384172726179286C656E293B20666F7220287661722069203D206C656E202D20313B2069203E3D20303B20692D2D29207B20615B695D203D206E2025203235363B206E203D204D617468';
wwv_flow_imp.g_varchar2_table(177) := '2E666C6F6F72286E202F20323536293B207D2072657475726E20613B207D0A2020202066756E6374696F6E20656C656D2869642C20706172747329207B2020202F2F2070617274733A2055696E74384172726179206C697374202D3E207B207061727473';
wwv_flow_imp.g_varchar2_table(178) := '2C2073697A65207D0A2020202020202020766172206C656E203D20302C206F7574203D205B69644279746573286964292C2073697A65382830295D3B0A202020202020202070617274732E666F72456163682866756E6374696F6E20287829207B206C65';
wwv_flow_imp.g_varchar2_table(179) := '6E202B3D20782E6C656E6774683B206F75742E707573682878293B207D293B0A20202020202020206F75745B315D203D2073697A6538286C656E293B0A202020202020202072657475726E207B2070617274733A206F75742C2073697A653A206F75745B';
wwv_flow_imp.g_varchar2_table(180) := '305D2E6C656E677468202B2038202B206C656E207D3B0A202020207D0A2020202066756E6374696F6E2075696E74456C656D2869642C206E2C206C656E29207B2072657475726E20656C656D2869642C205B75696E744279746573286E2C206C656E207C';
wwv_flow_imp.g_varchar2_table(181) := '7C2038295D293B207D0A2020202066756E6374696F6E20666C6174286C69737429207B20766172206F7574203D205B5D3B206C6973742E666F72456163682866756E6374696F6E20287829207B2041727261792E70726F746F747970652E707573682E61';
wwv_flow_imp.g_varchar2_table(182) := '70706C79286F75742C20782E7061727473293B207D293B2072657475726E206F75743B207D0A0A2020202066756E6374696F6E206669785765626D28626C6F622C2066616C6C6261636B4D7329207B0A202020202020202069662028212F7765626D2F69';
wwv_flow_imp.g_varchar2_table(183) := '2E7465737428626C6F622E74797065207C7C2022222929207B2072657475726E2050726F6D6973652E7265736F6C766528626C6F62293B207D0A202020202020202072657475726E20626C6F622E617272617942756666657228292E7468656E2866756E';
wwv_flow_imp.g_varchar2_table(184) := '6374696F6E202862756629207B0A2020202020202020202020207661722062203D206E65772055696E7438417272617928627566292C2070203D20302C20686561642C207365672C20736567456E642C20696E666F4B696473203D205B5D2C207363616C';
wwv_flow_imp.g_varchar2_table(185) := '65203D20313030303030302C20747261636B73203D206E756C6C2C206F7468657273203D205B5D2C0A20202020202020202020202020202020636C757374657273203D205B5D2C20747261636B203D20312C206D617854696D65203D20303B0A20202020';
wwv_flow_imp.g_varchar2_table(186) := '202020202020202068656164203D207265616456696E7428622C20302C2074727565293B0A20202020202020202020202069662028686561642E7620213D3D2045424D4C2E48454144455229207B2072657475726E20626C6F623B207D0A202020202020';
wwv_flow_imp.g_varchar2_table(187) := '202020202020766172206873203D207265616456696E7428622C20686561642E6C656E293B0A20202020202020202020202070203D20686561642E6C656E202B2068732E6C656E202B2068732E763B0A2020202020202020202020207661722068656164';
wwv_flow_imp.g_varchar2_table(188) := '65724279746573203D20622E737562617272617928302C2070293B0A202020202020202020202020736567203D207265616456696E7428622C20702C2074727565293B0A202020202020202020202020696620287365672E7620213D3D2045424D4C2E53';
wwv_flow_imp.g_varchar2_table(189) := '45474D454E5429207B2072657475726E20626C6F623B207D0A202020202020202020202020766172207373203D207265616456696E7428622C2070202B207365672E6C656E293B0A20202020202020202020202070202B3D207365672E6C656E202B2073';
wwv_flow_imp.g_varchar2_table(190) := '732E6C656E3B0A202020202020202020202020736567456E64203D2073732E756E6B6E6F776E203F20622E6C656E677468203A204D6174682E6D696E28622E6C656E6774682C2070202B2073732E76293B0A0A2020202020202020202020207768696C65';
wwv_flow_imp.g_varchar2_table(191) := '202870203C20736567456E6429207B0A20202020202020202020202020202020766172206964203D207265616456696E7428622C20702C2074727565292C20737A203D207265616456696E7428622C2070202B2069642E6C656E292C2064617461203D20';
wwv_flow_imp.g_varchar2_table(192) := '70202B2069642E6C656E202B20737A2E6C656E2C20656E643B0A202020202020202020202020202020206966202869642E76203D3D3D2045424D4C2E434C555354455229207B0A20202020202020202020202020202020202020202F2F20746865206368';
wwv_flow_imp.g_varchar2_table(193) := '696C6472656E20617265207265616420666F722074696D657374616D707320616E64206B65796672616D65733B2074686520636C757374657220626F647920697320636F70696564206173206F6E652070696563650A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(194) := '2020202020207661722063203D207B2074696D653A2030207D2C2071203D20646174612C2073746F70203D20737A2E756E6B6E6F776E203F20736567456E64203A204D6174682E6D696E28736567456E642C2064617461202B20737A2E76292C20637574';
wwv_flow_imp.g_varchar2_table(195) := '203D2066616C73653B0A20202020202020202020202020202020202020207768696C65202871203C2073746F7029207B0A20202020202020202020202020202020202020202020202076617220636964203D207265616456696E7428622C20712C207472';
wwv_flow_imp.g_varchar2_table(196) := '7565293B0A202020202020202020202020202020202020202020202020696620284C4556454C312E696E6465784F66286369642E7629203E3D203029207B20627265616B3B207D0A20202020202020202020202020202020202020202020202076617220';
wwv_flow_imp.g_varchar2_table(197) := '6373203D207265616456696E7428622C2071202B206369642E6C656E292C206364617461203D2071202B206369642E6C656E202B2063732E6C656E3B0A2020202020202020202020202020202020202020202020206966202863732E756E6B6E6F776E20';
wwv_flow_imp.g_varchar2_table(198) := '7C7C206364617461202B2063732E76203E20622E6C656E67746829207B20637574203D20747275653B20627265616B3B207D2020202F2F206375742D6F6666207461696C3A206B656570207768617420697320636F6D706C6574650A2020202020202020';
wwv_flow_imp.g_varchar2_table(199) := '20202020202020202020202020202020696620286369642E76203D3D3D2045424D4C2E54494D45434F444529207B20632E74696D65203D207265616455696E7428622C2063646174612C2063732E76293B207D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(200) := '202020202020202076617220626C6B203D206369642E76203D3D3D2045424D4C2E53494D504C45424C4F434B203F206364617461203A206369642E76203D3D3D2045424D4C2E424C4F434B47524F555020262620625B63646174615D203D3D3D2045424D';
wwv_flow_imp.g_varchar2_table(201) := '4C2E424C4F434B203F206364617461202B2031202B207265616456696E7428622C206364617461202B2031292E6C656E203A202D313B0A20202020202020202020202020202020202020202020202069662028626C6B203E3D203029207B0A2020202020';
wwv_flow_imp.g_varchar2_table(202) := '202020202020202020202020202020202020202020202076617220746E203D207265616456696E7428622C20626C6B292C2072656C203D2028625B626C6B202B20746E2E6C656E5D203C3C2038207C20625B626C6B202B20746E2E6C656E202B20315D29';
wwv_flow_imp.g_varchar2_table(203) := '3B0A202020202020202020202020202020202020202020202020202020206966202872656C203E20333237363729207B2072656C202D3D2036353533363B207D0A202020202020202020202020202020202020202020202020202020206D617854696D65';
wwv_flow_imp.g_varchar2_table(204) := '203D204D6174682E6D6178286D617854696D652C20632E74696D65202B2072656C293B0A202020202020202020202020202020202020202020202020202020202F2F20646F65732074686520636C757374657220737461727420776974682061206B6579';
wwv_flow_imp.g_varchar2_table(205) := '6672616D65206F66207468652063756520747261636B3F20286120426C6F636B47726F757020636F756E7473206173206F6E65290A2020202020202020202020202020202020202020202020202020202069662028632E6B6579203D3D3D20756E646566';
wwv_flow_imp.g_varchar2_table(206) := '696E656420262620746E2E76203D3D3D20747261636B29207B20632E6B6579203D206369642E7620213D3D2045424D4C2E53494D504C45424C4F434B207C7C2028625B626C6B202B20746E2E6C656E202B20325D202620307838302920213D3D20303B20';
wwv_flow_imp.g_varchar2_table(207) := '7D0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020202020202071203D206364617461202B2063732E763B0A20202020202020202020202020202020202020207D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(208) := '2020202020202020202020206966202871203E206461746129207B20632E626F6479203D20622E737562617272617928646174612C2071293B20636C7573746572732E707573682863293B207D0A20202020202020202020202020202020202020206966';
wwv_flow_imp.g_varchar2_table(209) := '2028637574207C7C2071203D3D3D206461746129207B20627265616B3B207D0A202020202020202020202020202020202020202070203D20713B0A2020202020202020202020202020202020202020636F6E74696E75653B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(210) := '20202020207D0A2020202020202020202020202020202069662028737A2E756E6B6E6F776E29207B2072657475726E20626C6F623B207D0A20202020202020202020202020202020656E64203D2064617461202B20737A2E763B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(211) := '202020202020206966202869642E76203D3D3D2045424D4C2E494E464F29207B0A2020202020202020202020202020202020202020666F7220287661722072203D20646174613B2072203C20656E643B29207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(212) := '202020202020202076617220696964203D207265616456696E7428622C20722C2074727565292C206973203D207265616456696E7428622C2072202B206969642E6C656E292C206964617461203D2072202B206969642E6C656E202B2069732E6C656E3B';
wwv_flow_imp.g_varchar2_table(213) := '0A202020202020202020202020202020202020202020202020696620286969642E76203D3D3D2045424D4C2E5343414C4529207B207363616C65203D207265616455696E7428622C2069646174612C2069732E76293B207D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(214) := '20202020202020202020202020696620286969642E7620213D3D2045424D4C2E4455524154494F4E29207B20696E666F4B6964732E7075736828622E737562617272617928722C206964617461202B2069732E7629293B207D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(215) := '202020202020202020202020202072203D206964617461202B2069732E763B0A20202020202020202020202020202020202020207D0A202020202020202020202020202020207D20656C7365206966202869642E76203D3D3D2045424D4C2E545241434B';
wwv_flow_imp.g_varchar2_table(216) := '5329207B0A2020202020202020202020202020202020202020747261636B73203D20622E737562617272617928702C20656E64293B0A2020202020202020202020202020202020202020666F7220287661722074203D20646174612C2066697273744E6F';
wwv_flow_imp.g_varchar2_table(217) := '203D20302C20766964656F4E6F203D20303B2074203C20656E643B29207B0A20202020202020202020202020202020202020202020202076617220746964203D207265616456696E7428622C20742C2074727565292C207473203D207265616456696E74';
wwv_flow_imp.g_varchar2_table(218) := '28622C2074202B207469642E6C656E292C207464617461203D2074202B207469642E6C656E202B2074732E6C656E3B0A202020202020202020202020202020202020202020202020696620287469642E76203D3D3D2045424D4C2E545241434B29207B0A';
wwv_flow_imp.g_varchar2_table(219) := '20202020202020202020202020202020202020202020202020202020766172206E6F203D20302C2074797065203D20303B0A20202020202020202020202020202020202020202020202020202020666F7220287661722075203D2074646174613B207520';
wwv_flow_imp.g_varchar2_table(220) := '3C207464617461202B2074732E763B29207B0A202020202020202020202020202020202020202020202020202020202020202076617220656964203D207265616456696E7428622C20752C2074727565292C206573203D207265616456696E7428622C20';
wwv_flow_imp.g_varchar2_table(221) := '75202B206569642E6C656E292C206564617461203D2075202B206569642E6C656E202B2065732E6C656E3B0A2020202020202020202020202020202020202020202020202020202020202020696620286569642E76203D3D3D2045424D4C2E545241434B';
wwv_flow_imp.g_varchar2_table(222) := '4E4F29207B206E6F203D207265616455696E7428622C2065646174612C2065732E76293B207D0A2020202020202020202020202020202020202020202020202020202020202020696620286569642E76203D3D3D2045424D4C2E545241434B5459504529';
wwv_flow_imp.g_varchar2_table(223) := '207B2074797065203D207265616455696E7428622C2065646174612C2065732E76293B207D0A202020202020202020202020202020202020202020202020202020202020202075203D206564617461202B2065732E763B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(224) := '202020202020202020202020202020207D0A2020202020202020202020202020202020202020202020202020202066697273744E6F203D2066697273744E6F207C7C206E6F3B0A2020202020202020202020202020202020202020202020202020202069';
wwv_flow_imp.g_varchar2_table(225) := '66202874797065203D3D3D20312026262021766964656F4E6F29207B20766964656F4E6F203D206E6F3B207D0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020202020202074203D2074';
wwv_flow_imp.g_varchar2_table(226) := '64617461202B2074732E763B0A20202020202020202020202020202020202020207D0A2020202020202020202020202020202020202020747261636B203D20766964656F4E6F207C7C2066697273744E6F207C7C20313B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(227) := '202020207D20656C7365206966202869642E7620213D3D2045424D4C2E5345454B484541442026262069642E7620213D3D2045424D4C2E564F49442026262069642E7620213D3D2045424D4C2E4355455329207B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(228) := '20202020206F74686572732E7075736828622E737562617272617928702C20656E6429293B0A202020202020202020202020202020207D0A2020202020202020202020202020202070203D20656E643B0A2020202020202020202020207D0A2020202020';
wwv_flow_imp.g_varchar2_table(229) := '202020202020206966202821747261636B73207C7C2021636C7573746572732E6C656E67746829207B2072657475726E20626C6F623B207D0A0A202020202020202020202020766172206475726174696F6E4D73203D206D617854696D65203E2030203F';
wwv_flow_imp.g_varchar2_table(230) := '206D617854696D65202A207363616C65202F20316536203A2066616C6C6261636B4D732C0A20202020202020202020202020202020647572203D206E6577204461746156696577286E6577204172726179427566666572283829293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(231) := '20202020206475722E736574466C6F6174363428302C206475726174696F6E4D73202A20316536202F207363616C65293B0A20202020202020202020202076617220696E666F203D20656C656D2845424D4C2E494E464F2C20696E666F4B6964732E636F';
wwv_flow_imp.g_varchar2_table(232) := '6E636174285B696442797465732845424D4C2E4455524154494F4E292C206E65772055696E74384172726179285B307838385D292C206E65772055696E74384172726179286475722E627566666572295D29292C0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(233) := '20636C7573746572456C73203D20636C7573746572732E6D61702866756E6374696F6E20286329207B2072657475726E20656C656D2845424D4C2E434C55535445522C205B632E626F64795D293B207D292C0A202020202020202020202020202020206F';
wwv_flow_imp.g_varchar2_table(234) := '7468657253697A65203D206F74686572732E7265647563652866756E6374696F6E2028732C207829207B2072657475726E2073202B20782E6C656E6774683B207D2C2030292C0A202020202020202020202020202020207365656B456E747279203D2066';
wwv_flow_imp.g_varchar2_table(235) := '756E6374696F6E202869642C20706F7329207B2072657475726E20656C656D2845424D4C2E5345454B2C20666C6174285B656C656D2845424D4C2E5345454B49442C205B69644279746573286964295D292C2075696E74456C656D2845424D4C2E534545';
wwv_flow_imp.g_varchar2_table(236) := '4B504F532C20706F73295D29293B207D2C0A202020202020202020202020202020207365656B53697A65203D20656C656D2845424D4C2E5345454B484541442C20666C6174285B7365656B456E7472792845424D4C2E494E464F2C2030292C207365656B';
wwv_flow_imp.g_varchar2_table(237) := '456E7472792845424D4C2E545241434B532C2030292C207365656B456E7472792845424D4C2E435545532C2030295D29292E73697A652C0A20202020202020202020202020202020696E666F506F73203D207365656B53697A652C20747261636B73506F';
wwv_flow_imp.g_varchar2_table(238) := '73203D20696E666F506F73202B20696E666F2E73697A652C20706F73203D20747261636B73506F73202B20747261636B732E6C656E677468202B206F7468657253697A652C20637565506F696E7473203D205B5D3B0A202020202020202020202020636C';
wwv_flow_imp.g_varchar2_table(239) := '7573746572456C732E666F72456163682866756E6374696F6E202863652C206929207B0A202020202020202020202020202020206966202869203D3D3D2030207C7C20636C7573746572735B695D2E6B657929207B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(240) := '202020202020637565506F696E74732E7075736828656C656D2845424D4C2E435545504F494E542C20666C6174285B75696E74456C656D2845424D4C2E43554554494D452C20636C7573746572735B695D2E74696D65292C0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(241) := '20202020202020202020202020656C656D2845424D4C2E435545504F532C20666C6174285B75696E74456C656D2845424D4C2E435545545241434B2C20747261636B2C2031292C2075696E74456C656D2845424D4C2E435545434C55535445522C20706F';
wwv_flow_imp.g_varchar2_table(242) := '73295D29295D2929293B0A202020202020202020202020202020207D0A20202020202020202020202020202020706F73202B3D2063652E73697A653B0A2020202020202020202020207D293B0A2020202020202020202020207661722063756573203D20';
wwv_flow_imp.g_varchar2_table(243) := '656C656D2845424D4C2E435545532C20666C617428637565506F696E747329292C0A202020202020202020202020202020207365656B48656164203D20656C656D2845424D4C2E5345454B484541442C20666C6174285B7365656B456E7472792845424D';
wwv_flow_imp.g_varchar2_table(244) := '4C2E494E464F2C20696E666F506F73292C207365656B456E7472792845424D4C2E545241434B532C20747261636B73506F73292C207365656B456E7472792845424D4C2E435545532C20706F73295D29292C0A2020202020202020202020202020202062';
wwv_flow_imp.g_varchar2_table(245) := '6F6479203D20666C6174285B7365656B486561642C20696E666F5D292E636F6E636174285B747261636B735D2C206F74686572732C20666C617428636C7573746572456C73292C20637565732E7061727473292C0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(246) := '20626F647953697A65203D20626F64792E7265647563652866756E6374696F6E2028732C207829207B2072657475726E2073202B20782E6C656E6774683B207D2C2030293B0A20202020202020202020202072657475726E206E657720426C6F62285B68';
wwv_flow_imp.g_varchar2_table(247) := '656164657242797465732C20696442797465732845424D4C2E5345474D454E54292C2073697A653828626F647953697A65295D2E636F6E63617428626F6479292C207B20747970653A20626C6F622E74797065207D293B0A20202020202020207D292E63';
wwv_flow_imp.g_varchar2_table(248) := '617463682866756E6374696F6E20286529207B0A2020202020202020202020206966202877696E646F772E636F6E736F6C6529207B20636F6E736F6C652E7761726E28224D65646961506C75733A205765624D206C656674206173207265636F72646564';
wwv_flow_imp.g_varchar2_table(249) := '222C2065293B207D0A20202020202020202020202072657475726E20626C6F623B0A20202020202020207D293B0A202020207D0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(250) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D204D5034207265706169720A202020202F2F204368726F6D6520616E64204564676520777269746520667261676D656E746564204D50343A20616E20656D707479206D6F6F762C207468';
wwv_flow_imp.g_varchar2_table(251) := '656E206D6F6F66202B206D64617420667261676D656E7473202D206F6E6520666F72207468652077686F6C65207265636F7264696E672E0A202020202F2F2057696E646F7773204D6564696120506C61796572207365656B73206F6E6C792066726F6D20';
wwv_flow_imp.g_varchar2_table(252) := '667261676D656E7420746F20667261676D656E742C20736F2069742063616E6E6F74207365656B20617420616C6C2C20616E64204368726F6D65277320747261636B0A202020202F2F206475726174696F6E73206172652077726F6E672E205468697320';
wwv_flow_imp.g_varchar2_table(253) := '7265777269746573206974206173206120726567756C6172204D50343A206D6F6F762066697273742077697468207468652066756C6C2073616D706C65207461626C65732028737474732C20637474732C0A202020202F2F20737473732C207374737A2C';
wwv_flow_imp.g_varchar2_table(254) := '20737473632C207374636F2920616E6420636F7272656374206475726174696F6E732C207468656E206F6E65206D6461742E20416E797468696E6720756E65787065637465642072657475726E7320746865206F726967696E616C2E0A2020202066756E';
wwv_flow_imp.g_varchar2_table(255) := '6374696F6E2075333228622C207029207B2072657475726E20625B705D202A203136373737323136202B2028625B70202B20315D203C3C20313629202B2028625B70202B20325D203C3C203829202B20625B70202B20335D3B207D0A2020202066756E63';
wwv_flow_imp.g_varchar2_table(256) := '74696F6E20626F78657328622C2073746172742C20656E6429207B0A2020202020202020766172206F7574203D205B5D3B0A2020202020202020666F7220287661722070203D2073746172743B2070202B2038203C3D20656E643B29207B0A2020202020';
wwv_flow_imp.g_varchar2_table(257) := '202020202020207661722073697A65203D2075333228622C2070292C2064617461203D2070202B20383B0A2020202020202020202020206966202873697A65203D3D3D203129207B2073697A65203D2075333228622C2070202B203829202A2034323934';
wwv_flow_imp.g_varchar2_table(258) := '393637323936202B2075333228622C2070202B203132293B2064617461203D2070202B2031363B207D20656C7365206966202873697A65203D3D3D203029207B2073697A65203D20656E64202D20703B207D0A2020202020202020202020206966202873';
wwv_flow_imp.g_varchar2_table(259) := '697A65203C2038207C7C2070202B2073697A65203E20656E6429207B207468726F77206E6577204572726F72282262616420626F7822293B207D0A2020202020202020202020206F75742E70757368287B20747970653A20537472696E672E66726F6D43';
wwv_flow_imp.g_varchar2_table(260) := '686172436F646528625B70202B20345D2C20625B70202B20355D2C20625B70202B20365D2C20625B70202B20375D292C2073746172743A20702C20646174613A20646174612C20656E643A2070202B2073697A65207D293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(261) := '2070202B3D2073697A653B0A20202020202020207D0A202020202020202072657475726E206F75743B0A202020207D0A2020202066756E6374696F6E206B69647328622C20626F782C207479706529207B2072657475726E20626F78657328622C20626F';
wwv_flow_imp.g_varchar2_table(262) := '782E646174612C20626F782E656E64292E66696C7465722866756E6374696F6E20287829207B2072657475726E202174797065207C7C20782E74797065203D3D3D20747970653B207D293B207D0A2020202066756E6374696F6E206D626F782874797065';
wwv_flow_imp.g_varchar2_table(263) := '2C20706172747329207B0A2020202020202020766172206C656E203D20382C206F75742C2070203D20383B0A202020202020202070617274732E666F72456163682866756E6374696F6E20287829207B206C656E202B3D20782E6C656E6774683B207D29';
wwv_flow_imp.g_varchar2_table(264) := '3B0A20202020202020206F7574203D206E65772055696E74384172726179286C656E293B0A20202020202020206F75742E7365742875696E744279746573286C656E2C2034292C2030293B0A2020202020202020666F7220287661722069203D20303B20';
wwv_flow_imp.g_varchar2_table(265) := '69203C20343B20692B2B29207B206F75745B34202B20695D203D20747970652E63686172436F646541742869293B207D0A202020202020202070617274732E666F72456163682866756E6374696F6E20287829207B206F75742E73657428782C2070293B';
wwv_flow_imp.g_varchar2_table(266) := '2070202B3D20782E6C656E6774683B207D293B0A202020202020202072657475726E206F75743B0A202020207D0A2020202066756E6374696F6E2066626F7828747970652C2076657273696F6E2C2076616C75657329207B2020202F2F2066756C6C2062';
wwv_flow_imp.g_varchar2_table(267) := '6F78206F662033322D6269742076616C7565730A20202020202020207661722061203D206E65772055696E743841727261792834202B2076616C7565732E6C656E677468202A2034292C206476203D206E657720446174615669657728612E6275666665';
wwv_flow_imp.g_varchar2_table(268) := '72293B0A2020202020202020615B305D203D2076657273696F6E3B0A202020202020202076616C7565732E666F72456163682866756E6374696F6E2028762C206929207B2064762E73657455696E7433322834202B2069202A20342C2076203E3E3E2030';
wwv_flow_imp.g_varchar2_table(269) := '293B207D293B0A202020202020202072657475726E206D626F7828747970652C205B615D293B0A202020207D0A2020202066756E6374696F6E2072756E73286C6973742C206F757429207B2020202F2F205B636F756E742C2076616C75652C20636F756E';
wwv_flow_imp.g_varchar2_table(270) := '742C2076616C7565202E2E2E5D0A20202020202020206C6973742E666F72456163682866756E6374696F6E20287629207B0A202020202020202020202020696620286F75742E6C656E677468202626206F75745B6F75742E6C656E677468202D20315D20';
wwv_flow_imp.g_varchar2_table(271) := '3D3D3D207629207B206F75745B6F75742E6C656E677468202D20325D2B2B3B207D20656C7365207B206F75742E7075736828312C2076293B207D0A20202020202020207D293B0A202020202020202072657475726E206F75743B0A202020207D0A0A2020';
wwv_flow_imp.g_varchar2_table(272) := '202066756E6374696F6E206669784D703428626C6F6229207B0A202020202020202069662028212F6D70347C6D34617C717569636B74696D652F692E7465737428626C6F622E74797065207C7C2022222929207B2072657475726E2050726F6D6973652E';
wwv_flow_imp.g_varchar2_table(273) := '7265736F6C766528626C6F62293B207D0A202020202020202072657475726E20626C6F622E617272617942756666657228292E7468656E2866756E6374696F6E202862756629207B0A2020202020202020202020207661722062203D206E65772055696E';
wwv_flow_imp.g_varchar2_table(274) := '7438417272617928627566292C206476203D206E657720446174615669657728627566292C20746F70203D20626F78657328622C20302C20622E6C656E677468292C206D6F6F762C206D7668642C20747261636B73203D207B7D2C206F72646572203D20';
wwv_flow_imp.g_varchar2_table(275) := '5B5D2C2074726578203D207B7D2C206578747261203D205B5D3B0A2020202020202020202020206D6F6F76203D20746F702E66696C7465722866756E6374696F6E20287829207B2072657475726E20782E74797065203D3D3D20226D6F6F76223B207D29';
wwv_flow_imp.g_varchar2_table(276) := '5B305D3B0A20202020202020202020202069662028216D6F6F76207C7C2021746F702E736F6D652866756E6374696F6E20287829207B2072657475726E20782E74797065203D3D3D20226D6F6F66223B207D2929207B2072657475726E20626C6F623B20';
wwv_flow_imp.g_varchar2_table(277) := '7D2020202F2F20616C7265616479206120726567756C6172204D50340A2020202020202020202020206B69647328622C206D6F6F76292E666F72456163682866756E6374696F6E20286B29207B0A20202020202020202020202020202020696620286B2E';
wwv_flow_imp.g_varchar2_table(278) := '74797065203D3D3D20226D7668642229207B0A20202020202020202020202020202020202020206D766864203D206B3B0A202020202020202020202020202020207D20656C736520696620286B2E74797065203D3D3D20227472616B2229207B0A202020';
wwv_flow_imp.g_varchar2_table(279) := '202020202020202020202020202020202076617220746B6864203D206B69647328622C206B2C2022746B686422295B305D2C206D646961203D206B69647328622C206B2C20226D64696122295B305D2C206D646864203D206B69647328622C206D646961';
wwv_flow_imp.g_varchar2_table(280) := '2C20226D64686422295B305D2C0A20202020202020202020202020202020202020202020202068646C72203D206B69647328622C206D6469612C202268646C7222295B305D2C206D696E66203D206B69647328622C206D6469612C20226D696E6622295B';
wwv_flow_imp.g_varchar2_table(281) := '305D2C207374626C203D206B69647328622C206D696E662C20227374626C22295B305D2C0A2020202020202020202020202020202020202020202020206964203D2075333228622C20746B68642E64617461202B2028625B746B68642E646174615D203D';
wwv_flow_imp.g_varchar2_table(282) := '3D3D2031203F203230203A20313229293B0A2020202020202020202020202020202020202020747261636B735B69645D203D207B207472616B3A206B2C20746B68643A20746B68642C206D6469613A206D6469612C206D6468643A206D6468642C206D69';
wwv_flow_imp.g_varchar2_table(283) := '6E663A206D696E662C20737473643A206B69647328622C207374626C2C20227374736422295B305D2C0A2020202020202020202020202020202020202020202020207363616C653A2075333228622C206D6468642E64617461202B2028625B6D6468642E';
wwv_flow_imp.g_varchar2_table(284) := '646174615D203D3D3D2031203F203230203A20313229292C20766964656F3A2068646C722026262075333228622C2068646C722E64617461202B203829203D3D3D20307837363639363436352C0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(285) := '2020647572733A205B5D2C2073697A65733A205B5D2C2063746F733A205B5D2C2073796E633A205B5D2C206368756E6B733A205B5D207D3B0A20202020202020202020202020202020202020206F726465722E70757368286964293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(286) := '2020202020202020207D20656C736520696620286B2E74797065203D3D3D20226D7665782229207B0A20202020202020202020202020202020202020206B69647328622C206B2C20227472657822292E666F72456163682866756E6374696F6E20287829';
wwv_flow_imp.g_varchar2_table(287) := '207B0A202020202020202020202020202020202020202020202020747265785B75333228622C20782E64617461202B2034295D203D207B206475723A2075333228622C20782E64617461202B203132292C2073697A653A2075333228622C20782E646174';
wwv_flow_imp.g_varchar2_table(288) := '61202B203136292C20666C6167733A2075333228622C20782E64617461202B20323029207D3B0A20202020202020202020202020202020202020207D293B0A202020202020202020202020202020207D20656C7365207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(289) := '202020202020202065787472612E7075736828622E7375626172726179286B2E73746172742C206B2E656E6429293B2020202F2F20756474612C206D657461202E2E2E0A202020202020202020202020202020207D0A2020202020202020202020207D29';
wwv_flow_imp.g_varchar2_table(290) := '3B0A20202020202020202020202069662028216D766864207C7C20216F726465722E6C656E67746829207B2072657475726E20626C6F623B207D0A0A2020202020202020202020202F2F2073616D706C6573206F6620657665727920667261676D656E74';
wwv_flow_imp.g_varchar2_table(291) := '0A202020202020202020202020746F702E666F72456163682866756E6374696F6E20286D29207B0A20202020202020202020202020202020696620286D2E7479706520213D3D20226D6F6F662229207B2072657475726E3B207D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(292) := '202020202020206B69647328622C206D2C20227472616622292E666F72456163682866756E6374696F6E2028746629207B0A202020202020202020202020202020202020202076617220746B203D206B69647328622C207466292C2074666864203D2074';
wwv_flow_imp.g_varchar2_table(293) := '6B2E66696C7465722866756E6374696F6E20287829207B2072657475726E20782E74797065203D3D3D202274666864223B207D295B305D2C0A202020202020202020202020202020202020202020202020666C203D2075333228622C20746668642E6461';
wwv_flow_imp.g_varchar2_table(294) := '74612920262030784646464646462C2071203D20746668642E64617461202B20382C206964203D2075333228622C20746668642E64617461202B2034292C2074203D20747261636B735B69645D2C2064203D20747265785B69645D207C7C207B7D2C0A20';
wwv_flow_imp.g_varchar2_table(295) := '202020202020202020202020202020202020202020202062617365203D206D2E73746172742C2064447572203D20642E647572207C7C20302C206453697A65203D20642E73697A65207C7C20302C2064466C616773203D20642E666C616773207C7C2030';
wwv_flow_imp.g_varchar2_table(296) := '2C20706F733B0A202020202020202020202020202020202020202069662028666C2026203129207B2062617365203D2075333228622C207129202A2034323934393637323936202B2075333228622C2071202B2034293B2071202B3D20383B207D0A2020';
wwv_flow_imp.g_varchar2_table(297) := '20202020202020202020202020202020202069662028666C2026203229207B2071202B3D20343B207D0A202020202020202020202020202020202020202069662028666C2026203829207B2064447572203D2075333228622C2071293B2071202B3D2034';
wwv_flow_imp.g_varchar2_table(298) := '3B207D0A202020202020202020202020202020202020202069662028666C2026203078313029207B206453697A65203D2075333228622C2071293B2071202B3D20343B207D0A202020202020202020202020202020202020202069662028666C20262030';
wwv_flow_imp.g_varchar2_table(299) := '78323029207B2064466C616773203D2075333228622C2071293B207D0A202020202020202020202020202020202020202069662028217429207B2072657475726E3B207D0A2020202020202020202020202020202020202020706F73203D20626173653B';
wwv_flow_imp.g_varchar2_table(300) := '0A2020202020202020202020202020202020202020746B2E666F72456163682866756E6374696F6E2028747229207B0A2020202020202020202020202020202020202020202020206966202874722E7479706520213D3D20227472756E2229207B207265';
wwv_flow_imp.g_varchar2_table(301) := '7475726E3B207D0A2020202020202020202020202020202020202020202020207661722076203D20625B74722E646174615D2C2066203D2075333228622C2074722E646174612920262030784646464646462C206E203D2075333228622C2074722E6461';
wwv_flow_imp.g_varchar2_table(302) := '7461202B2034292C2072203D2074722E64617461202B20382C206669727374203D206E756C6C2C2073746172743B0A20202020202020202020202020202020202020202020202069662028662026203129207B20706F73203D2062617365202B2064762E';
wwv_flow_imp.g_varchar2_table(303) := '676574496E7433322872293B2072202B3D20343B207D0A20202020202020202020202020202020202020202020202069662028662026203429207B206669727374203D2075333228622C2072293B2072202B3D20343B207D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(304) := '202020202020202020202020207374617274203D20706F733B0A202020202020202020202020202020202020202020202020666F7220287661722069203D20303B2069203C206E3B20692B2B29207B0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(305) := '2020202020202020766172207364203D20644475722C207373203D206453697A652C207366203D2064466C6167732C2063203D20303B0A202020202020202020202020202020202020202020202020202020206966202866202620307831303029207B20';
wwv_flow_imp.g_varchar2_table(306) := '7364203D2075333228622C2072293B2072202B3D20343B207D0A202020202020202020202020202020202020202020202020202020206966202866202620307832303029207B207373203D2075333228622C2072293B2072202B3D20343B207D0A202020';
wwv_flow_imp.g_varchar2_table(307) := '202020202020202020202020202020202020202020202020206966202866202620307834303029207B207366203D2075333228622C2072293B2072202B3D20343B207D0A2020202020202020202020202020202020202020202020202020202069662028';
wwv_flow_imp.g_varchar2_table(308) := '66202620307838303029207B2063203D2076203F2064762E676574496E743332287229203A2075333228622C2072293B2072202B3D20343B207D0A202020202020202020202020202020202020202020202020202020206966202869203D3D3D20302026';
wwv_flow_imp.g_varchar2_table(309) := '2620666972737420213D3D206E756C6C29207B207366203D2066697273743B207D0A20202020202020202020202020202020202020202020202020202020742E647572732E70757368287364293B20742E73697A65732E70757368287373293B20742E63';
wwv_flow_imp.g_varchar2_table(310) := '746F732E707573682863293B20742E73796E632E7075736828212873662026203078313030303029293B0A20202020202020202020202020202020202020202020202020202020706F73202B3D2073733B0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(311) := '2020202020207D0A20202020202020202020202020202020202020202020202069662028706F73203E20622E6C656E67746829207B207468726F77206E6577204572726F7228226375742D6F66662073616D706C65206461746122293B207D0A20202020';
wwv_flow_imp.g_varchar2_table(312) := '2020202020202020202020202020202020202020696620286E29207B20742E6368756E6B732E70757368287B2066726F6D3A2073746172742C2073697A653A20706F73202D2073746172742C20636F756E743A206E207D293B207D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(313) := '2020202020202020202020207D293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D293B0A0A2020202020202020202020202F2F20746865206D646174206B6565707320746865206F726967696E616C20696E7465';
wwv_flow_imp.g_varchar2_table(314) := '726C656176696E673A206368756E6B7320696E2066696C65206F726465720A20202020202020202020202076617220616C6C203D205B5D2C20746F74616C203D20303B0A2020202020202020202020206F726465722E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(315) := '6F6E2028696429207B20616C6C203D20616C6C2E636F6E63617428747261636B735B69645D2E6368756E6B73293B207D293B0A2020202020202020202020206966202821616C6C2E6C656E67746829207B2072657475726E20626C6F623B207D0A202020';
wwv_flow_imp.g_varchar2_table(316) := '202020202020202020616C6C2E736F72742866756E6374696F6E2028782C207929207B2072657475726E20782E66726F6D202D20792E66726F6D3B207D292E666F72456163682866756E6374696F6E20286329207B20632E6174203D20746F74616C3B20';
wwv_flow_imp.g_varchar2_table(317) := '746F74616C202B3D20632E73697A653B207D293B0A20202020202020202020202069662028746F74616C203E203430303030303030303029207B2072657475726E20626C6F623B207D0A0A202020202020202020202020766172206D5363616C65203D20';
wwv_flow_imp.g_varchar2_table(318) := '75333228622C206D7668642E64617461202B2028625B6D7668642E646174615D203D3D3D2031203F203230203A20313229292C206D447572203D20303B0A2020202020202020202020206F726465722E666F72456163682866756E6374696F6E20286964';
wwv_flow_imp.g_varchar2_table(319) := '29207B0A202020202020202020202020202020207661722074203D20747261636B735B69645D3B0A20202020202020202020202020202020742E647572203D20742E647572732E7265647563652866756E6374696F6E2028732C207829207B2072657475';
wwv_flow_imp.g_varchar2_table(320) := '726E2073202B20783B207D2C2030293B0A20202020202020202020202020202020742E6D447572203D204D6174682E726F756E6428742E647572202A206D5363616C65202F20742E7363616C65293B0A202020202020202020202020202020206D447572';
wwv_flow_imp.g_varchar2_table(321) := '203D204D6174682E6D6178286D4475722C20742E6D447572293B0A2020202020202020202020207D293B0A2020202020202020202020202F2F20636F7079206F66206120626F78207769746820697473206475726174696F6E206669656C64207265706C';
wwv_flow_imp.g_varchar2_table(322) := '6163656420286D766864202F206D6468643A206166746572207468652074696D657363616C653B20746B68643A2061667465722074686520747261636B206964290A2020202020202020202020207661722077697468447572203D2066756E6374696F6E';
wwv_flow_imp.g_varchar2_table(323) := '2028626F782C2076302C2076312C2076616C756529207B0A202020202020202020202020202020207661722061203D20622E736C69636528626F782E73746172742C20626F782E656E64292C2064203D206E657720446174615669657728612E62756666';
wwv_flow_imp.g_varchar2_table(324) := '6572292C206F203D20626F782E64617461202D20626F782E73746172743B0A2020202020202020202020202020202069662028615B6F5D203D3D3D203129207B20642E73657455696E743332286F202B2076312C204D6174682E666C6F6F722876616C75';
wwv_flow_imp.g_varchar2_table(325) := '65202F203432393439363732393629293B20642E73657455696E743332286F202B207631202B20342C2076616C7565203E3E3E2030293B207D20656C7365207B20642E73657455696E743332286F202B2076302C2076616C7565203E3E3E2030293B207D';
wwv_flow_imp.g_varchar2_table(326) := '0A2020202020202020202020202020202072657475726E20613B0A2020202020202020202020207D3B0A20202020202020202020202076617220636F7079203D2066756E6374696F6E2028626F7829207B2072657475726E20622E737562617272617928';
wwv_flow_imp.g_varchar2_table(327) := '626F782E73746172742C20626F782E656E64293B207D3B0A2020202020202020202020202F2F20747261636B206865616465723A20656E61626C6564202B20696E206D6F766965202B20696E207072657669657720285361666172692077726974657320';
wwv_flow_imp.g_varchar2_table(328) := '22656E61626C656422206F6E6C792C207768696368204170706C65277320706C61796572206F6620610A2020202020202020202020202F2F20726567756C6172204D5034206D6179206E6F7420706C6179292C20616E642066756C6C20766F6C756D6520';
wwv_flow_imp.g_varchar2_table(329) := '6F6E20736F756E6420747261636B730A20202020202020202020202076617220747261636B486561646572203D2066756E6374696F6E2028626F782C207429207B0A202020202020202020202020202020207661722061203D207769746844757228626F';
wwv_flow_imp.g_varchar2_table(330) := '782C2032302C2032382C20742E6D447572292C206F203D20626F782E64617461202D20626F782E73746172742C2064203D206E657720446174615669657728612E627566666572293B0A20202020202020202020202020202020615B6F202B20335D203D';
wwv_flow_imp.g_varchar2_table(331) := '20615B6F202B20335D207C20373B0A202020202020202020202020202020206966202821742E766964656F29207B20642E73657455696E743136286F202B2028615B6F5D203D3D3D2031203F203438203A203336292C20307830313030293B207D0A2020';
wwv_flow_imp.g_varchar2_table(332) := '202020202020202020202020202072657475726E20613B0A2020202020202020202020207D3B0A202020202020202020202020766172206275696C64203D2066756E6374696F6E20286261736529207B0A20202020202020202020202020202020766172';
wwv_flow_imp.g_varchar2_table(333) := '207472616B73203D206F726465722E6D61702866756E6374696F6E2028696429207B0A20202020202020202020202020202020202020207661722074203D20747261636B735B69645D2C2073747473203D2072756E7328742E647572732C205B5D292C20';
wwv_flow_imp.g_varchar2_table(334) := '63747473203D2072756E7328742E63746F732C205B5D292C2073747363203D205B5D2C207374636F203D205B5D2C2073747373203D205B5D2C2070726576203D202D312C0A2020202020202020202020202020202020202020202020207461626C657320';
wwv_flow_imp.g_varchar2_table(335) := '3D205B636F707928742E73747364292C2066626F78282273747473222C20302C205B737474732E6C656E677468202F20325D2E636F6E636174287374747329295D3B0A202020202020202020202020202020202020202069662028742E63746F732E736F';
wwv_flow_imp.g_varchar2_table(336) := '6D652866756E6374696F6E20287829207B2072657475726E207820213D3D20303B207D2929207B0A2020202020202020202020202020202020202020202020207461626C65732E707573682866626F78282263747473222C20742E63746F732E736F6D65';
wwv_flow_imp.g_varchar2_table(337) := '2866756E6374696F6E20287829207B2072657475726E2078203C20303B207D29203F2031203A20302C205B637474732E6C656E677468202F20325D2E636F6E63617428637474732929293B0A20202020202020202020202020202020202020207D0A2020';
wwv_flow_imp.g_varchar2_table(338) := '202020202020202020202020202020202020742E73796E632E666F72456163682866756E6374696F6E2028732C206929207B20696620287329207B20737473732E707573682869202B2031293B207D207D293B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(339) := '2020202069662028742E766964656F20262620737473732E6C656E677468203C20742E73796E632E6C656E67746829207B207461626C65732E707573682866626F78282273747373222C20302C205B737473732E6C656E6774685D2E636F6E6361742873';
wwv_flow_imp.g_varchar2_table(340) := '7473732929293B207D0A20202020202020202020202020202020202020207461626C65732E707573682866626F7828227374737A222C20302C205B302C20742E73697A65732E6C656E6774685D2E636F6E63617428742E73697A65732929293B0A202020';
wwv_flow_imp.g_varchar2_table(341) := '2020202020202020202020202020202020742E6368756E6B732E666F72456163682866756E6374696F6E2028632C206929207B0A20202020202020202020202020202020202020202020202069662028632E636F756E7420213D3D207072657629207B20';
wwv_flow_imp.g_varchar2_table(342) := '737473632E707573682869202B20312C20632E636F756E742C2031293B2070726576203D20632E636F756E743B207D0A2020202020202020202020202020202020202020202020207374636F2E707573682862617365202B20632E6174293B0A20202020';
wwv_flow_imp.g_varchar2_table(343) := '202020202020202020202020202020207D293B0A20202020202020202020202020202020202020207461626C65732E707573682866626F78282273747363222C20302C205B737473632E6C656E677468202F20335D2E636F6E636174287374736329292C';
wwv_flow_imp.g_varchar2_table(344) := '2066626F7828227374636F222C20302C205B7374636F2E6C656E6774685D2E636F6E636174287374636F2929293B0A2020202020202020202020202020202020202020766172206D696E66203D206D626F7828226D696E66222C206B69647328622C2074';
wwv_flow_imp.g_varchar2_table(345) := '2E6D696E66292E66696C7465722866756E6374696F6E20287829207B2072657475726E20782E7479706520213D3D20227374626C223B207D292E6D617028636F7079292E636F6E636174285B6D626F7828227374626C222C207461626C6573295D29292C';
wwv_flow_imp.g_varchar2_table(346) := '0A2020202020202020202020202020202020202020202020206D646961203D206D626F7828226D646961222C206B69647328622C20742E6D646961292E6D61702866756E6374696F6E20287829207B0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(347) := '202020202020202072657475726E20782E74797065203D3D3D20226D64686422203F207769746844757228782C2031362C2032342C20742E64757229203A20782E74797065203D3D3D20226D696E6622203F206D696E66203A20636F70792878293B0A20';
wwv_flow_imp.g_varchar2_table(348) := '20202020202020202020202020202020202020202020207D29293B0A20202020202020202020202020202020202020202F2F2065647473206973206C656674206F75743A207468652065646974206C69737473206F6620667261676D656E746564206669';
wwv_flow_imp.g_varchar2_table(349) := '6C65732064657363726962652074686520667261676D656E74730A202020202020202020202020202020202020202072657475726E206D626F7828227472616B222C206B69647328622C20742E7472616B292E66696C7465722866756E6374696F6E2028';
wwv_flow_imp.g_varchar2_table(350) := '7829207B2072657475726E20782E7479706520213D3D202265647473223B207D292E6D61702866756E6374696F6E20287829207B0A20202020202020202020202020202020202020202020202072657475726E20782E74797065203D3D3D2022746B6864';
wwv_flow_imp.g_varchar2_table(351) := '22203F20747261636B48656164657228782C207429203A20782E74797065203D3D3D20226D64696122203F206D646961203A20636F70792878293B0A20202020202020202020202020202020202020207D29293B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(352) := '207D293B0A2020202020202020202020202020202072657475726E206D626F7828226D6F6F76222C205B77697468447572286D7668642C2031362C2032342C206D447572295D2E636F6E636174287472616B732C20657874726129293B0A202020202020';
wwv_flow_imp.g_varchar2_table(353) := '2020202020207D3B0A2020202020202020202020207661722066747970203D206D626F78282266747970222C205B2269736F6D222C20225C305C305C75303030325C30222C202269736F6D222C202269736F32222C202261766331222C20226D70343122';
wwv_flow_imp.g_varchar2_table(354) := '5D2E6D61702866756E6374696F6E20287329207B0A202020202020202020202020202020202020202072657475726E206E65772055696E7438417272617928732E73706C6974282222292E6D61702866756E6374696F6E2028636829207B207265747572';
wwv_flow_imp.g_varchar2_table(355) := '6E2063682E63686172436F646541742830293B207D29293B0A202020202020202020202020202020207D29292C0A2020202020202020202020202020202073697A65203D206275696C642830292E6C656E6774682C0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(356) := '20206D6F6F76426F78203D206275696C6428667479702E6C656E677468202B2073697A65202B2038292C0A202020202020202020202020202020207061727473203D205B667479702C206D6F6F76426F782C2075696E74427974657328746F74616C202B';
wwv_flow_imp.g_varchar2_table(357) := '20382C2034292C206E65772055696E74384172726179285B307836442C20307836342C20307836312C20307837345D295D3B0A202020202020202020202020616C6C2E666F72456163682866756E6374696F6E20286329207B2070617274732E70757368';
wwv_flow_imp.g_varchar2_table(358) := '28622E737562617272617928632E66726F6D2C20632E66726F6D202B20632E73697A6529293B207D293B0A20202020202020202020202072657475726E206E657720426C6F622870617274732C207B20747970653A20626C6F622E74797065207D293B0A';
wwv_flow_imp.g_varchar2_table(359) := '20202020202020207D292E63617463682866756E6374696F6E20286529207B0A2020202020202020202020206966202877696E646F772E636F6E736F6C6529207B20636F6E736F6C652E7761726E28224D65646961506C75733A204D5034206C65667420';
wwv_flow_imp.g_varchar2_table(360) := '6173207265636F72646564222C2065293B207D0A20202020202020202020202072657475726E20626C6F623B0A20202020202020207D293B0A202020207D0A0A2020202066756E6374696F6E206669784D6564696128626C6F622C2066616C6C6261636B';
wwv_flow_imp.g_varchar2_table(361) := '4D7329207B0A202020202020202072657475726E202F7765626D2F692E7465737428626C6F622E74797065207C7C20222229203F206669785765626D28626C6F622C2066616C6C6261636B4D7329203A206669784D703428626C6F62293B0A202020207D';
wwv_flow_imp.g_varchar2_table(362) := '0A0A202020202F2F20694F5320285361666172692031362E342B293A207768696C6520746865206D6963726F70686F6E65206973206F70656E20746865207061676520706C617973207468726F756768207468652065617270696563652C20617320696E';
wwv_flow_imp.g_varchar2_table(363) := '20612070686F6E652063616C6C2C0A202020202F2F20616E6420737461797320736F206166746572207265636F7264696E6720756E6C65737320746F6C64206F7468657277697365202D207468656E2061207265636F7264696E67206A757374206D6164';
wwv_flow_imp.g_varchar2_table(364) := '65206973206E6F742068656172642E2054686520417564696F0A202020202F2F2053657373696F6E20415049207377697463686573206265747765656E207265636F7264696E6720616E64206E6F726D616C20706C61796261636B3B206F746865722062';
wwv_flow_imp.g_varchar2_table(365) := '726F777365727320646F206E6F74206861766520697420616E64206E656564206E6F7468696E672E0A2020202066756E6374696F6E20617564696F53657373696F6E287479706529207B0A2020202020202020747279207B20696620286E617669676174';
wwv_flow_imp.g_varchar2_table(366) := '6F722E617564696F53657373696F6E202626206E6176696761746F722E617564696F53657373696F6E2E7479706520213D3D207479706529207B206E6176696761746F722E617564696F53657373696F6E2E74797065203D20747970653B207D207D2063';
wwv_flow_imp.g_varchar2_table(367) := '6174636820286529207B202F2A206E6F7420737570706F72746564202A2F207D0A202020207D0A0A2020202066756E6374696F6E206B696E644F66286D696D6529207B0A2020202020202020766172206B203D20537472696E67286D696D65207C7C2022';
wwv_flow_imp.g_varchar2_table(368) := '22292E73706C697428222F22295B305D2E746F55707065724361736528293B0A202020202020202072657475726E206B203D3D3D2022564944454F22207C7C206B203D3D3D2022494D41474522203F206B203A2022415544494F223B0A202020207D0A0A';
wwv_flow_imp.g_varchar2_table(369) := '202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2070686F746F730A202020202F2F20412070686F746F2069732065';
wwv_flow_imp.g_varchar2_table(370) := '6469746564206173206120736D616C6C20736574206F662073657474696E677320287475726E2C20666C69702C2063726F702C2061646A7573746D656E74732C2064726177696E6729206F6E2069747320736F7572636520706963747572653B0A202020';
wwv_flow_imp.g_varchar2_table(371) := '202F2F20746865207069637475726520697473656C66206973206F6E6C792072656E646572656420666F7220746865207072657669657720616E64206F6E6365206D6F72652C20617420746865206F75747075742073697A652C207768656E2069742069';
wwv_flow_imp.g_varchar2_table(372) := '7320757365642E0A202020207661722046494C5445525F4F4B203D202866756E6374696F6E202829207B0A2020202020202020747279207B2072657475726E20747970656F6620646F63756D656E742E637265617465456C656D656E74282263616E7661';
wwv_flow_imp.g_varchar2_table(373) := '7322292E676574436F6E746578742822326422292E66696C746572203D3D3D2022737472696E67223B207D20636174636820286529207B2072657475726E2066616C73653B207D0A202020207D2928293B0A0A2020202066756E6374696F6E2063616E76';
wwv_flow_imp.g_varchar2_table(374) := '61734F6628772C206829207B0A20202020202020207661722063203D20646F63756D656E742E637265617465456C656D656E74282263616E76617322293B0A2020202020202020632E7769647468203D204D6174682E6D617828312C204D6174682E726F';
wwv_flow_imp.g_varchar2_table(375) := '756E64287729293B0A2020202020202020632E686569676874203D204D6174682E6D617828312C204D6174682E726F756E64286829293B0A202020202020202072657475726E20633B0A202020207D0A0A2020202066756E6374696F6E20656E636F6465';
wwv_flow_imp.g_varchar2_table(376) := '2863616E7661732C20747970652C207175616C69747929207B0A202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20287265736F6C76652C2072656A65637429207B0A20202020202020202020202063616E766173';
wwv_flow_imp.g_varchar2_table(377) := '2E746F426C6F622866756E6374696F6E20286229207B20696620286229207B207265736F6C76652862293B207D20656C7365207B2072656A656374286E6577204572726F722822656E636F64652229293B207D207D2C20747970652C207175616C697479';
wwv_flow_imp.g_varchar2_table(378) := '293B0A20202020202020207D293B0A202020207D0A0A202020202F2F206465636F64657320612070686F746F20287468652062726F77736572206170706C696573207468652045584946206F7269656E746174696F6E2920696E746F20612063616E7661';
wwv_flow_imp.g_varchar2_table(379) := '73206F66206174206D6F73742050484F544F5F534F555243455F4D41582070780A2020202066756E6374696F6E206C6F616450686F746F28626C6F6229207B0A202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(380) := '287265736F6C76652C2072656A65637429207B0A2020202020202020202020207661722075726C203D2055524C2E6372656174654F626A65637455524C28626C6F62292C20696D67203D206E657720496D61676528293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(381) := '696D672E6F6E6C6F6164203D2066756E6374696F6E202829207B0A2020202020202020202020202020202055524C2E7265766F6B654F626A65637455524C2875726C293B0A202020202020202020202020202020207661722077203D20696D672E6E6174';
wwv_flow_imp.g_varchar2_table(382) := '7572616C57696474682C2068203D20696D672E6E61747572616C4865696768742C2073203D204D6174682E6D696E28312C2050484F544F5F534F555243455F4D4158202F204D6174682E6D617828772C206829293B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(383) := '2020696620282177207C7C20216829207B2072656A656374286E6577204572726F722822656D7074792229293B2072657475726E3B207D0A202020202020202020202020202020207661722063203D2063616E7661734F662877202A20732C2068202A20';
wwv_flow_imp.g_varchar2_table(384) := '73292C2067203D20632E676574436F6E746578742822326422293B0A20202020202020202020202020202020672E696D616765536D6F6F7468696E675175616C697479203D202268696768223B0A20202020202020202020202020202020672E64726177';
wwv_flow_imp.g_varchar2_table(385) := '496D61676528696D672C20302C20302C20632E77696474682C20632E686569676874293B0A202020202020202020202020202020207265736F6C76652863293B0A2020202020202020202020207D3B0A202020202020202020202020696D672E6F6E6572';
wwv_flow_imp.g_varchar2_table(386) := '726F72203D2066756E6374696F6E202829207B2055524C2E7265766F6B654F626A65637455524C2875726C293B2072656A656374286E6577204572726F7228626C6F622E74797065207C7C20222229293B207D3B0A202020202020202020202020696D67';
wwv_flow_imp.g_varchar2_table(387) := '2E737263203D2075726C3B0A20202020202020207D293B0A202020207D0A0A2020202066756E6374696F6E2066696C7465724F6628656429207B0A20202020202020207661722066203D205B5D3B0A20202020202020206966202865642E61646A2E6220';
wwv_flow_imp.g_varchar2_table(388) := '213D3D2031303029207B20662E7075736828226272696768746E6573732822202B2065642E61646A2E62202B2022252922293B207D0A20202020202020206966202865642E61646A2E6320213D3D2031303029207B20662E707573682822636F6E747261';
wwv_flow_imp.g_varchar2_table(389) := '73742822202B2065642E61646A2E63202B2022252922293B207D0A20202020202020206966202865642E61646A2E7320213D3D20313030202626202165642E6772617929207B20662E70757368282273617475726174652822202B2065642E61646A2E73';
wwv_flow_imp.g_varchar2_table(390) := '202B2022252922293B207D0A20202020202020206966202865642E6772617929207B20662E707573682822677261797363616C6528312922293B207D0A202020202020202072657475726E20662E6A6F696E28222022293B0A202020207D0A0A20202020';
wwv_flow_imp.g_varchar2_table(391) := '2F2F207468652073616D652061646A7573746D656E74732062792068616E642C20666F722062726F777365727320776974686F75742063616E7661732066696C7465727320286F6C64657220536166617269290A2020202066756E6374696F6E2061646A';
wwv_flow_imp.g_varchar2_table(392) := '757374506978656C7328672C20772C20682C20656429207B0A20202020202020207661722064203D20672E676574496D6167654461746128302C20302C20772C2068292C2070203D20642E646174612C2062203D2065642E61646A2E62202F203130302C';
wwv_flow_imp.g_varchar2_table(393) := '206B203D2065642E61646A2E63202F203130302C2073203D2065642E67726179203F2030203A2065642E61646A2E73202F203130303B0A2020202020202020666F7220287661722069203D20303B2069203C20702E6C656E6774683B2069202B3D203429';
wwv_flow_imp.g_varchar2_table(394) := '207B0A2020202020202020202020207661722072203D2028705B695D202A2062202D2031323829202A206B202B203132382C206772203D2028705B69202B20315D202A2062202D2031323829202A206B202B203132382C20626C203D2028705B69202B20';
wwv_flow_imp.g_varchar2_table(395) := '325D202A2062202D2031323829202A206B202B203132382C0A202020202020202020202020202020206C203D20302E32313236202A2072202B20302E37313532202A206772202B20302E30373232202A20626C3B0A202020202020202020202020705B69';
wwv_flow_imp.g_varchar2_table(396) := '5D203D206C202B202872202D206C29202A20733B0A202020202020202020202020705B69202B20315D203D206C202B20286772202D206C29202A20733B0A202020202020202020202020705B69202B20325D203D206C202B2028626C202D206C29202A20';
wwv_flow_imp.g_varchar2_table(397) := '733B0A20202020202020207D0A2020202020202020672E707574496D6167654461746128642C20302C2030293B0A202020207D0A0A202020202F2F207374726F6B657320617265206B65707420696E20736F7572636520636F6F7264696E617465732028';
wwv_flow_imp.g_varchar2_table(398) := '302E2E31292C20736F2074686579207475726E20616E642063726F702077697468207468652070686F746F0A2020202066756E6374696F6E20647261775374726F6B657328672C207374726F6B65732C20772C206829207B0A2020202020202020737472';
wwv_flow_imp.g_varchar2_table(399) := '6F6B65732E666F72456163682866756E6374696F6E2028737429207B0A202020202020202020202020696620282173742E7074732E6C656E67746829207B2072657475726E3B207D0A202020202020202020202020672E7361766528293B0A2020202020';
wwv_flow_imp.g_varchar2_table(400) := '20202020202020672E7374726F6B655374796C65203D2073742E636F6C6F75723B0A202020202020202020202020672E6C696E655769647468203D204D6174682E6D617828312C2073742E77202A204D6174682E6D617828772C206829293B0A20202020';
wwv_flow_imp.g_varchar2_table(401) := '2020202020202020672E6C696E65436170203D20672E6C696E654A6F696E203D2022726F756E64223B0A202020202020202020202020672E626567696E5061746828293B0A202020202020202020202020672E6D6F7665546F2873742E7074735B305D5B';
wwv_flow_imp.g_varchar2_table(402) := '305D202A20772C2073742E7074735B305D5B315D202A2068293B0A202020202020202020202020666F7220287661722069203D20313B2069203C2073742E7074732E6C656E6774683B20692B2B29207B20672E6C696E65546F2873742E7074735B695D5B';
wwv_flow_imp.g_varchar2_table(403) := '305D202A20772C2073742E7074735B695D5B315D202A2068293B207D0A2020202020202020202020206966202873742E7074732E6C656E677468203D3D3D203129207B20672E6C696E65546F2873742E7074735B305D5B305D202A2077202B20302E312C';
wwv_flow_imp.g_varchar2_table(404) := '2073742E7074735B305D5B315D202A2068293B207D0A202020202020202020202020672E7374726F6B6528293B0A202020202020202020202020672E726573746F726528293B0A20202020202020207D293B0A202020207D0A0A202020202F2F20746865';
wwv_flow_imp.g_varchar2_table(405) := '206564697465642070686F746F3A2061646A7573746D656E747320616E642064726177696E67206F6E2074686520736F757263652C207468656E207475726E656420616E6420666C69707065642C207468656E2063726F7070656420287768656E206173';
wwv_flow_imp.g_varchar2_table(406) := '6B6564292C0A202020202F2F207363616C656420736F207468617420697473206C6F6E676573742073696465206973206174206D6F7374206D6178536964650A2020202066756E6374696F6E2072656E64657250686F746F2865642C206D617853696465';
wwv_flow_imp.g_varchar2_table(407) := '2C2063726F7070656429207B0A2020202020202020766172207377203D2065642E7372632E77696474682C207368203D2065642E7372632E6865696768742C207475726E6564203D2065642E726F7420252031383020213D3D20302C0A20202020202020';
wwv_flow_imp.g_varchar2_table(408) := '20202020207477203D207475726E6564203F207368203A2073772C207468203D207475726E6564203F207377203A2073682C0A20202020202020202020202063203D2063726F70706564203F2065642E63726F70203A207B20783A20302C20793A20302C';
wwv_flow_imp.g_varchar2_table(409) := '20773A20312C20683A2031207D2C0A20202020202020202020202073203D204D6174682E6D696E28312C206D617853696465202F204D6174682E6D617828632E77202A2074772C20632E68202A20746829292C0A2020202020202020202020206C617965';
wwv_flow_imp.g_varchar2_table(410) := '72203D2063616E7661734F66287377202A20732C207368202A2073292C2067203D206C617965722E676574436F6E746578742822326422292C2066203D2066696C7465724F66286564293B0A2020202020202020672E696D616765536D6F6F7468696E67';
wwv_flow_imp.g_varchar2_table(411) := '5175616C697479203D202268696768223B0A202020202020202069662028662026262046494C5445525F4F4B29207B20672E66696C746572203D20663B207D0A2020202020202020672E64726177496D6167652865642E7372632C20302C20302C206C61';
wwv_flow_imp.g_varchar2_table(412) := '7965722E77696474682C206C617965722E686569676874293B0A202020202020202069662028662026262046494C5445525F4F4B29207B20672E66696C746572203D20226E6F6E65223B207D0A20202020202020206966202866202626202146494C5445';
wwv_flow_imp.g_varchar2_table(413) := '525F4F4B29207B2061646A757374506978656C7328672C206C617965722E77696474682C206C617965722E6865696768742C206564293B207D0A2020202020202020647261775374726F6B657328672C2065642E7374726F6B65732C206C617965722E77';
wwv_flow_imp.g_varchar2_table(414) := '696474682C206C617965722E686569676874293B0A2020202020202020766172206F7574203D2063616E7661734F6628632E77202A207477202A20732C20632E68202A207468202A2073292C206F203D206F75742E676574436F6E746578742822326422';
wwv_flow_imp.g_varchar2_table(415) := '293B0A20202020202020206F2E696D616765536D6F6F7468696E675175616C697479203D202268696768223B0A20202020202020206F2E7472616E736C617465282D632E78202A207477202A2073202B207477202A2073202F20322C202D632E79202A20';
wwv_flow_imp.g_varchar2_table(416) := '7468202A2073202B207468202A2073202F2032293B0A20202020202020206F2E726F746174652865642E726F74202A204D6174682E5049202F20313830293B0A20202020202020206F2E7363616C652865642E666C6970203F202D31203A20312C203129';
wwv_flow_imp.g_varchar2_table(417) := '3B0A20202020202020206F2E64726177496D616765286C617965722C202D6C617965722E7769647468202F20322C202D6C617965722E686569676874202F2032293B0A202020202020202072657475726E206F75743B0A202020207D0A0A202020202F2F';
wwv_flow_imp.g_varchar2_table(418) := '20656E636F646573207468652070686F746F3B207768696C65206974206973206F766572206D617842797465732C20666972737420746865207175616C69747920676F657320646F776E2028746F20302E35292C207468656E207468652073697A652028';
wwv_flow_imp.g_varchar2_table(419) := '627920323025290A2020202066756E6374696F6E20656E636F6465546F4669742865642C206D6178536964652C20747970652C207175616C6974792C206D6178427974657329207B0A20202020202020207661722073696465203D206D6178536964652C';
wwv_flow_imp.g_varchar2_table(420) := '2071203D207175616C6974792C207472696573203D20303B0A20202020202020207661722073746570203D2066756E6374696F6E202829207B0A2020202020202020202020207661722063203D2072656E64657250686F746F2865642C20736964652C20';
wwv_flow_imp.g_varchar2_table(421) := '74727565293B0A20202020202020202020202072657475726E20656E636F646528632C20747970652C2071292E7468656E2866756E6374696F6E20286229207B0A202020202020202020202020202020202F2F20612062726F7773657220746861742063';
wwv_flow_imp.g_varchar2_table(422) := '616E6E6F7420777269746520576562502072657475726E7320504E473A20757365204A50454720696E73746561640A202020202020202020202020202020206966202874797065203D3D3D2022696D6167652F776562702220262620622E747970652021';
wwv_flow_imp.g_varchar2_table(423) := '3D3D207479706529207B2074797065203D2022696D6167652F6A706567223B2072657475726E207374657028293B207D0A2020202020202020202020202020202069662028622E73697A65203C3D206D61784279746573207C7C202B2B7472696573203E';
wwv_flow_imp.g_varchar2_table(424) := '20313229207B2072657475726E207B20626C6F623A20622C2077696474683A20632E77696474682C206865696768743A20632E6865696768742C20666974733A20622E73697A65203C3D206D61784279746573207D3B207D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(425) := '2020202020696620287479706520213D3D2022696D6167652F706E67222026262071203E20302E353529207B2071203D204D6174682E6D617828302E352C2071202D20302E31293B207D20656C7365207B2073696465203D204D6174682E726F756E6428';
wwv_flow_imp.g_varchar2_table(426) := '4D6174682E6D617828632E77696474682C20632E68656967687429202A20302E38293B207D0A2020202020202020202020202020202072657475726E207374657028293B0A2020202020202020202020207D293B0A20202020202020207D3B0A20202020';
wwv_flow_imp.g_varchar2_table(427) := '2020202072657475726E207374657028293B0A202020207D0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D20';
wwv_flow_imp.g_varchar2_table(428) := '7265636F726465720A2020202066756E6374696F6E205265636F726465722863666729207B0A20202020202020207661722073656C66203D20746869733B0A2020202020202020746869732E636667203D206366673B0A2020202020202020746869732E';
wwv_flow_imp.g_varchar2_table(429) := '696E707574203D20646F63756D656E742E676574456C656D656E7442794964286366672E6974656D293B0A2020202020202020746869732E726F6F74203D20646F63756D656E742E676574456C656D656E7442794964286366672E6974656D202B20225F';
wwv_flow_imp.g_varchar2_table(430) := '4D504C555322293B0A2020202020202020746869732E6665617475726573203D20286366672E6665617475726573207C7C202222292E73706C697428223A22293B0A2020202020202020746869732E617564696F4F707473203D20286366672E61756469';
wwv_flow_imp.g_varchar2_table(431) := '6F4F7074696F6E73207C7C202222292E73706C697428223A22293B0A20202020202020202F2F204D6F64653A20616E79206F6620415544494F2C20564944454F2C20494D4147452028636F6C6F6E206C697374293B20746865206669727374206F6E6520';
wwv_flow_imp.g_varchar2_table(432) := '69732073656C65637465640A2020202020202020746869732E6B696E6473203D20537472696E67286366672E6D6F6465207C7C2022415544494F22292E746F4C6F7765724361736528292E73706C697428223A22292E66696C7465722866756E6374696F';
wwv_flow_imp.g_varchar2_table(433) := '6E20286B29207B2072657475726E206B203D3D3D2022617564696F22207C7C206B203D3D3D2022766964656F22207C7C206B203D3D3D2022696D616765223B207D293B0A20202020202020206966202821746869732E6B696E64732E6C656E6774682920';
wwv_flow_imp.g_varchar2_table(434) := '7B20746869732E6B696E6473203D205B22617564696F225D3B207D0A2020202020202020746869732E6B696E64203D20746869732E6B696E64735B305D3B0A2020202020202020746869732E746F6F6C73203D20537472696E67286366672E696D616765';
wwv_flow_imp.g_varchar2_table(435) := '546F6F6C73207C7C202222292E73706C697428223A22292E66696C74657228426F6F6C65616E293B0A2020202020202020746869732E666163696E67203D206366672E63616D657261203D3D3D20227573657222203F20227573657222203A2022656E76';
wwv_flow_imp.g_varchar2_table(436) := '69726F6E6D656E74223B0A2020202020202020746869732E7374617465203D202269646C65223B0A2020202020202020746869732E6974656D73203D20286366672E6974656D73207C7C205B5D292E6D61702866756E6374696F6E20287229207B20722E';
wwv_flow_imp.g_varchar2_table(437) := '70656E64696E67203D20747275653B2072657475726E20723B207D293B0A2020202020202020746869732E7361766564203D206366672E7361766564207C7C205B5D3B0A2020202020202020746869732E696E697469616C203D20746869732E696E7075';
wwv_flow_imp.g_varchar2_table(438) := '742E76616C75653B0A2020202020202020746869732E64697361626C6564203D2066616C73653B0A2020202020202020746869732E64726166744B6579203D20226D706C75733A22202B20286366672E6170704964207C7C20222229202B20223A22202B';
wwv_flow_imp.g_varchar2_table(439) := '20286366672E706167654964207C7C20222229202B20223A22202B206366672E6974656D3B0A2020202020202020746869732E737570706F72746564203D2021212877696E646F772E4D656469615265636F72646572202626206E6176696761746F722E';
wwv_flow_imp.g_varchar2_table(440) := '6D6564696144657669636573202626206E6176696761746F722E6D65646961446576696365732E676574557365724D656469612026262077696E646F772E6973536563757265436F6E7465787420213D3D2066616C7365293B0A20202020202020207468';
wwv_flow_imp.g_varchar2_table(441) := '69732E5352203D2077696E646F772E5370656563685265636F676E6974696F6E207C7C2077696E646F772E7765626B69745370656563685265636F676E6974696F6E3B0A20202020202020202F2F20456E676C697368202855532920616E64202F206F72';
wwv_flow_imp.g_varchar2_table(442) := '204172616269633B20776974686F757420612063686F696365207468652070616765206C616E677561676520646563696465730A2020202020202020746869732E6C616E6773203D20537472696E67286366672E7472616E7363726970744C616E677561';
wwv_flow_imp.g_varchar2_table(443) := '676573207C7C202222292E73706C6974282F5B2C3B3A5C735D2B2F292E66696C7465722866756E6374696F6E20286C29207B2072657475726E204C414E47532E696E6465784F66286C29203E3D20303B207D293B0A202020202020202069662028217468';
wwv_flow_imp.g_varchar2_table(444) := '69732E6C616E67732E6C656E67746829207B20746869732E6C616E6773203D205B2F5E61722F692E7465737428646F63756D656E742E646F63756D656E74456C656D656E742E6C616E67207C7C20222229203F202261722D534122203A2022656E2D5553';
wwv_flow_imp.g_varchar2_table(445) := '225D3B207D0A2020202020202020747279207B20746869732E6C616E67203D206C6F63616C53746F726167652E6765744974656D28226D706C75732D6C616E673A22202B206366672E6974656D293B207D20636174636820286529207B20746869732E6C';
wwv_flow_imp.g_varchar2_table(446) := '616E67203D206E756C6C3B207D0A202020202020202069662028746869732E6C616E67732E696E6465784F6628746869732E6C616E6729203C203029207B20746869732E6C616E67203D20746869732E6C616E67735B305D3B207D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(447) := '746869732E6275696C6428293B0A2020202020202020746869732E73796E6328293B0A202020202020202069662028746869732E686173282273776974636843616D6572612229202626206E6176696761746F722E6D6564696144657669636573202626';
wwv_flow_imp.g_varchar2_table(448) := '206E6176696761746F722E6D65646961446576696365732E656E756D65726174654465766963657329207B0A2020202020202020202020206E6176696761746F722E6D65646961446576696365732E656E756D65726174654465766963657328292E7468';
wwv_flow_imp.g_varchar2_table(449) := '656E2866756E6374696F6E20286C69737429207B0A2020202020202020202020202020202073656C662E63616D65726173203D206C6973742E66696C7465722866756E6374696F6E20286429207B2072657475726E20642E6B696E64203D3D3D20227669';
wwv_flow_imp.g_varchar2_table(450) := '64656F696E707574223B207D292E6C656E6774683B0A2020202020202020202020202020202073656C662E73796E6328293B0A2020202020202020202020207D292E63617463682866756E6374696F6E202829207B202F2A206E6F20646576696365206C';
wwv_flow_imp.g_varchar2_table(451) := '697374202D206B6565702074686520627574746F6E2068696464656E202A2F207D293B0A20202020202020207D0A202020202020202069662028216366672E726561644F6E6C7929207B20746869732E7265636F76657228293B207D0A202020207D0A0A';
wwv_flow_imp.g_varchar2_table(452) := '202020205265636F726465722E70726F746F747970652E686173203D2066756E6374696F6E20286629207B2072657475726E20746869732E66656174757265732E696E6465784F66286629203E3D20303B207D3B0A0A202020205265636F726465722E70';
wwv_flow_imp.g_varchar2_table(453) := '726F746F747970652E7175616C697479203D2066756E6374696F6E202829207B0A20202020202020207661722071203D20746869732E6366672E7175616C697479203D3D3D2022435553544F4D22203F20746869732E636667203A202850524553455453';
wwv_flow_imp.g_varchar2_table(454) := '5B746869732E6366672E7175616C6974795D207C7C20505245534554532E42414C414E434544293B0A202020202020202072657475726E207B20617564696F4B6270733A202B712E617564696F4B627073207C7C2034382C20766964656F4B6270733A20';
wwv_flow_imp.g_varchar2_table(455) := '2B712E766964656F4B627073207C7C203930302C20766964656F4865696768743A202B712E766964656F486569676874207C7C203438302C206670733A202B712E667073207C7C203234207D3B0A202020207D3B0A0A202020202F2F2041414320284D50';
wwv_flow_imp.g_varchar2_table(456) := '3420617564696F2920736F756E647320706F6F722062656C6F77203936206B6270732C20616E64204368726F6D65207265636F7264732069742061742061626F757420313030206B6270732077686174657665722069732061736B65643B0A202020202F';
wwv_flow_imp.g_varchar2_table(457) := '2F204F7075732069732066696E6520617420746865207072657365742072617465730A202020205265636F726465722E70726F746F747970652E617564696F4B627073203D2066756E6374696F6E20286D696D6529207B0A202020202020202076617220';
wwv_flow_imp.g_varchar2_table(458) := '71203D20746869732E7175616C69747928292E617564696F4B6270733B0A202020202020202072657475726E202F6D70342F692E74657374286D696D65203D3D3D20756E646566696E6564203F207069636B4D696D6528746869732E6B696E642C207468';
wwv_flow_imp.g_varchar2_table(459) := '69732E6366672E666F726D617429203A206D696D6529203F204D6174682E6D61782839362C207129203A20713B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E77697468536F756E64203D2066756E6374696F6E202829';
wwv_flow_imp.g_varchar2_table(460) := '207B2072657475726E20746869732E6B696E64203D3D3D2022617564696F22207C7C2028746869732E6B696E64203D3D3D2022766964656F2220262620746869732E617564696F4F7074732E696E6465784F662822766964656F536F756E642229203E3D';
wwv_flow_imp.g_varchar2_table(461) := '2030293B207D3B0A0A202020202F2F20766964656F20616E642070686F746F7320757365207468652063616D6572610A202020205265636F726465722E70726F746F747970652E63616D657261203D2066756E6374696F6E202829207B2072657475726E';
wwv_flow_imp.g_varchar2_table(462) := '20746869732E6B696E6420213D3D2022617564696F223B207D3B0A0A202020202F2F206C697665207472616E736372697074696F6E206170706C69657320746F20617564696F207265636F7264696E67730A202020205265636F726465722E70726F746F';
wwv_flow_imp.g_varchar2_table(463) := '747970652E7472616E73637269626573203D2066756E6374696F6E202829207B2072657475726E20746869732E6366672E7472616E736372697074696F6E203D3D3D20224C4956452220262620746869732E6B696E64203D3D3D2022617564696F223B20';
wwv_flow_imp.g_varchar2_table(464) := '7D3B0A0A202020205265636F726465722E70726F746F747970652E6275696C64203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C2063203D20746869732E6366672C2072203D20746869732E726F6F';
wwv_flow_imp.g_varchar2_table(465) := '742C207468203D20632E627574746F6E73203D3D3D20225448454D45223B0A2020202020202020722E636C6173734C6973742E61646428226D706C75732D2D22202B2028632E7374796C65203D3D3D2022434F4D5041435422203F2022636F6D70616374';
wwv_flow_imp.g_varchar2_table(466) := '22203A202266756C6C2229293B0A2020202020202020722E636C6173734C6973742E746F67676C6528226D706C75732D2D7468656D652D627574746F6E73222C207468293B0A2020202020202020722E696E6E657248544D4C203D2022223B0A0A202020';
wwv_flow_imp.g_varchar2_table(467) := '20202020202F2F20746F70206C696E653A20417564696F202F20566964656F202F2050686F746F207377697463682C207472616E736372697074696F6E206C616E67756167652C207374617475730A2020202020202020746869732E736567203D20656C';
wwv_flow_imp.g_varchar2_table(468) := '2822646976222C20226D706C75732D736567222C207B20726F6C653A202267726F7570222C2022617269612D6C6162656C223A2074787428224B494E44532229207D293B0A2020202020202020746869732E73656742746E73203D207B7D3B0A20202020';
wwv_flow_imp.g_varchar2_table(469) := '20202020746869732E6B696E64732E666F72456163682866756E6374696F6E20286B29207B0A2020202020202020202020207661722062203D2063746C28226D706C75732D7365672D62746E206D706C75732D7365672D22202B206B2C207B2061756469';
wwv_flow_imp.g_varchar2_table(470) := '6F3A202266612D6D6963726F70686F6E65222C20766964656F3A202266612D766964656F2D63616D657261222C20696D6167653A202266612D63616D65726122207D5B6B5D2C20747874286B2E746F557070657243617365282929293B0A202020202020';
wwv_flow_imp.g_varchar2_table(471) := '202020202020622E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E7365744B696E64286B293B207D293B0A20202020202020202020202073656C662E73656742746E735B6B5D203D2062';
wwv_flow_imp.g_varchar2_table(472) := '3B0A20202020202020202020202073656C662E7365672E617070656E644368696C642862293B0A20202020202020207D293B0A2020202020202020746869732E6C616E6753656C203D20656C282273656C656374222C20226D706C75732D6C616E67222C';
wwv_flow_imp.g_varchar2_table(473) := '207B2022617269612D6C6162656C223A2074787428225452414E5343524950545F4C414E475541474522292C207469746C653A2074787428225452414E5343524950545F4C414E47554147452229207D293B0A2020202020202020746869732E6C616E67';
wwv_flow_imp.g_varchar2_table(474) := '732E666F72456163682866756E6374696F6E20286C29207B0A202020202020202020202020766172206E616D65203D206C3B0A202020202020202020202020747279207B206E616D65203D206E657720496E746C2E446973706C61794E616D6573285B64';
wwv_flow_imp.g_varchar2_table(475) := '6F63756D656E742E646F63756D656E74456C656D656E742E6C616E67207C7C2022656E225D2C207B20747970653A20226C616E677561676522207D292E6F66286C29207C7C206C3B207D20636174636820286529207B202F2A206B656570207468652063';
wwv_flow_imp.g_varchar2_table(476) := '6F6465202A2F207D0A20202020202020202020202073656C662E6C616E6753656C2E617070656E644368696C6428656C28226F7074696F6E222C206E756C6C2C207B2076616C75653A206C2C20746578743A206E616D652C2073656C65637465643A206C';
wwv_flow_imp.g_varchar2_table(477) := '203D3D3D2073656C662E6C616E67207D29293B0A20202020202020207D293B0A2020202020202020746869732E737461747573203D20656C28227370616E222C20226D706C75732D737461747573222C207B2022617269612D6C697665223A2022706F6C';
wwv_flow_imp.g_varchar2_table(478) := '69746522207D293B0A2020202020202020746869732E746F70203D20656C2822646976222C20226D706C75732D746F70222C206E756C6C2C205B746869732E6B696E64732E6C656E677468203E20312026262021632E726561644F6E6C79203F20746869';
wwv_flow_imp.g_varchar2_table(479) := '732E736567203A206E756C6C2C20746869732E6C616E6753656C2C20746869732E7374617475735D293B0A0A20202020202020202F2F2073746167653A206C6976652063616D657261202F2077617665666F726D2C2074696D65722C20636F756E74646F';
wwv_flow_imp.g_varchar2_table(480) := '776E0A2020202020202020746869732E766964656F203D20656C2822766964656F222C20226D706C75732D6C697665222C207B20706C617973696E6C696E653A20747275652C206D757465643A20747275652C206175746F706C61793A2074727565207D';
wwv_flow_imp.g_varchar2_table(481) := '293B0A2020202020202020746869732E766964656F2E6D75746564203D20747275653B0A2020202020202020746869732E63616E766173203D20656C282263616E766173222C20226D706C75732D77617665222C207B2022617269612D68696464656E22';
wwv_flow_imp.g_varchar2_table(482) := '3A20227472756522207D293B0A2020202020202020746869732E74696D6572203D20656C28227370616E222C20226D706C75732D74696D6572222C207B20746578743A2022303A3030222C20726F6C653A202274696D657222207D293B0A202020202020';
wwv_flow_imp.g_varchar2_table(483) := '2020746869732E646F74203D20656C28227370616E222C20226D706C75732D646F74222C207B2022617269612D68696464656E223A20227472756522207D293B0A2020202020202020746869732E6C6576656C203D20656C28227370616E222C20226D70';
wwv_flow_imp.g_varchar2_table(484) := '6C75732D6C6576656C222C207B2022617269612D68696464656E223A20227472756522207D2C205B656C28227370616E22295D293B0A2020202020202020746869732E636F756E74646F776E203D20656C28227370616E222C20226D706C75732D636F75';
wwv_flow_imp.g_varchar2_table(485) := '6E74646F776E222C207B2022617269612D6C697665223A202261737365727469766522207D293B0A2020202020202020746869732E7374616765203D20656C2822646976222C20226D706C75732D7374616765222C206E756C6C2C205B0A202020202020';
wwv_flow_imp.g_varchar2_table(486) := '202020202020746869732E766964656F2C20746869732E63616E7661732C0A202020202020202020202020656C2822646976222C20226D706C75732D6F7665726C6179222C206E756C6C2C205B656C28227370616E222C20226D706C75732D726563222C';
wwv_flow_imp.g_varchar2_table(487) := '206E756C6C2C205B746869732E646F742C20746869732E74696D65725D292C20746869732E6C6576656C5D292C0A202020202020202020202020746869732E636F756E74646F776E0A20202020202020205D293B0A2020202020202020746869732E7669';
wwv_flow_imp.g_varchar2_table(488) := '64656F2E6164644576656E744C697374656E65722822726573697A65222C2066756E6374696F6E202829207B2073656C662E66697453746167652873656C662E766964656F2E766964656F57696474682C2073656C662E766964656F2E766964656F4865';
wwv_flow_imp.g_varchar2_table(489) := '69676874293B207D293B0A0A20202020202020202F2F206C697665207472616E736372697074207768696C65207265636F7264696E670A2020202020202020746869732E73747446696E616C456C203D20656C28227370616E22293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(490) := '20746869732E737474496E746572696D456C203D20656C28227370616E222C20226D706C75732D7374742D696E746572696D22293B0A2020202020202020746869732E737474426F78203D20656C2822646976222C20226D706C75732D737474222C207B';
wwv_flow_imp.g_varchar2_table(491) := '2022617269612D6C697665223A2022706F6C69746522207D2C205B746869732E73747446696E616C456C2C20746869732E737474496E746572696D456C5D293B0A0A20202020202020202F2F2074696D65202F2073697A65206D657465720A2020202020';
wwv_flow_imp.g_varchar2_table(492) := '202020746869732E6D6574657246696C6C203D20656C28227370616E222C20226D706C75732D6D657465722D66696C6C22293B0A2020202020202020746869732E6D6574657254657874203D20656C28227370616E222C20226D706C75732D6D65746572';
wwv_flow_imp.g_varchar2_table(493) := '2D7465787422293B0A2020202020202020746869732E6D65746572426172203D20656C28227370616E222C20226D706C75732D6D657465722D747261636B222C207B20726F6C653A202270726F6772657373626172222C2022617269612D76616C75656D';
wwv_flow_imp.g_varchar2_table(494) := '696E223A20302C2022617269612D76616C75656D6178223A20313030207D2C205B746869732E6D6574657246696C6C5D293B0A2020202020202020746869732E6D65746572203D20656C2822646976222C20226D706C75732D6D65746572222C206E756C';
wwv_flow_imp.g_varchar2_table(495) := '6C2C205B746869732E6D657465724261722C20746869732E6D65746572546578745D293B0A0A2020202020202020746869732E6E6F74696365203D20656C2822646976222C20226D706C75732D6E6F74696365222C207B20726F6C653A20227374617475';
wwv_flow_imp.g_varchar2_table(496) := '7322207D293B0A0A20202020202020202F2F20636F6E74726F6C730A2020202020202020746869732E625265636F7264203D2063746C28226D706C75732D62746E2D2D726563206D706C75732D622D7265636F7264222C2022726563222C207478742822';
wwv_flow_imp.g_varchar2_table(497) := '5245434F524422292C2066616C73652C207468293B0A2020202020202020746869732E625061757365203D2063746C28226D706C75732D622D7061757365222C20227061757365222C207478742822504155534522292C2066616C73652C207468293B0A';
wwv_flow_imp.g_varchar2_table(498) := '2020202020202020746869732E6250617573652E6D706C75734B6579203D202250223B0A2020202020202020746869732E6253746F70203D2063746C28226D706C75732D62746E2D2D73746F70206D706C75732D622D73746F70222C202273746F70222C';
wwv_flow_imp.g_varchar2_table(499) := '20747874282253544F5022292C2066616C73652C207468293B0A2020202020202020746869732E6253746F702E6D706C75734B6579203D202253223B0A2020202020202020746869732E62537769746368203D2063746C28226D706C75732D622D737769';
wwv_flow_imp.g_varchar2_table(500) := '746368222C202266612D72656672657368222C2074787428225357495443485F43414D45524122292C20747275652C207468293B0A2020202020202020746869732E62436C6F7365203D2063746C28226D706C75732D62746E2D2D67686F7374206D706C';
wwv_flow_imp.g_varchar2_table(501) := '75732D622D636C6F7365222C202266612D74696D6573222C207478742822434C4F53455F43414D45524122292C2066616C73652C207468293B0A2020202020202020746869732E6246696C65203D2063746C28226D706C75732D62746E2D2D67686F7374';
wwv_flow_imp.g_varchar2_table(502) := '206D706C75732D622D66696C65222C202266612D75706C6F6164222C20746869732E737570706F72746564203F20747874282243484F4F53455F46494C452229203A2074787428224445564943455F5245434F5244455222292C2066616C73652C207468';
wwv_flow_imp.g_varchar2_table(503) := '293B0A2020202020202020746869732E66696C65203D20656C2822696E707574222C20226D706C75732D66696C65222C207B20747970653A202266696C65222C2068696464656E3A20747275652C20746162696E6465783A20222D31222C0A2020202020';
wwv_flow_imp.g_varchar2_table(504) := '202020202020206163636570743A20746869732E6B696E64732E6D61702866756E6374696F6E20286B29207B2072657475726E206B202B20222F2A223B207D292E6A6F696E28222C22292C0A2020202020202020202020202F2F20776974686F75742063';
wwv_flow_imp.g_varchar2_table(505) := '616D657261206163636573732C207468652070686F6E652773206F776E2063616D657261202F207265636F726465720A202020202020202020202020636170747572653A20746869732E737570706F72746564203F206E756C6C203A2028746869732E6B';
wwv_flow_imp.g_varchar2_table(506) := '696E64735B305D203D3D3D2022617564696F22203F20227573657222203A2022656E7669726F6E6D656E742229207D293B0A2020202020202020746869732E616374696F6E73203D20656C2822646976222C20226D706C75732D616374696F6E73206D70';
wwv_flow_imp.g_varchar2_table(507) := '6C75732D616374696F6E732D2D6D61696E222C206E756C6C2C205B746869732E625265636F72642C20746869732E6250617573652C20746869732E6253746F702C20746869732E625377697463682C20746869732E62436C6F73652C20746869732E6246';
wwv_flow_imp.g_varchar2_table(508) := '696C652C20746869732E66696C655D293B0A2020202020202020746869732E68696E74203D20656C2822646976222C20226D706C75732D68696E7422293B0A0A20202020202020202F2F207265766965772061667465722073746F700A20202020202020';
wwv_flow_imp.g_varchar2_table(509) := '20746869732E706C61796572203D20656C2822646976222C20226D706C75732D7265766965772D706C6179657222293B0A2020202020202020746869732E62557365203D2063746C28226D706C75732D62746E2D2D7072696D617279206D706C75732D62';
wwv_flow_imp.g_varchar2_table(510) := '2D757365222C202266612D636865636B222C20747874282255534522292C2066616C73652C207468293B0A2020202020202020746869732E62416761696E203D2063746C28226D706C75732D622D616761696E222C202266612D756E646F222C20747874';
wwv_flow_imp.g_varchar2_table(511) := '2822414741494E22292C2066616C73652C207468293B0A2020202020202020746869732E6244697363617264203D2063746C28226D706C75732D62746E2D2D67686F7374206D706C75732D622D64697363617264222C202266612D74726173682D6F222C';
wwv_flow_imp.g_varchar2_table(512) := '2074787428224449534341524422292C2066616C73652C207468293B0A2020202020202020746869732E61446F776E6C6F6164203D20656C282261222C20287468203F20226D706C75732D62746E2D2D7468656D6520742D427574746F6E20742D427574';
wwv_flow_imp.g_varchar2_table(513) := '746F6E2D2D736D616C6C20742D427574746F6E2D2D6E6F554920742D427574746F6E2D2D69636F6E4C65667422203A20226D706C75732D62746E206D706C75732D62746E2D2D67686F73742229202B2022206D706C75732D622D646F776E6C6F6164222C';
wwv_flow_imp.g_varchar2_table(514) := '207B20687265663A20222322207D2C0A202020202020202020202020202020202020202020202020202020205B656C28227370616E222C20226D706C75732D692066612066612D646F776E6C6F616422202B20287468203F202220742D49636F6E20742D';
wwv_flow_imp.g_varchar2_table(515) := '49636F6E2D2D6C65667422203A202222292C207B2022617269612D68696464656E223A20227472756522207D292C0A2020202020202020202020202020202020202020202020202020202020656C28227370616E222C20226D706C75732D62746E2D6C61';
wwv_flow_imp.g_varchar2_table(516) := '62656C22202B20287468203F202220742D427574746F6E2D6C6162656C22203A202222292C207B20746578743A207478742822444F574E4C4F41442229207D295D293B0A2020202020202020746869732E7265766965774D657461203D20656C28227370';
wwv_flow_imp.g_varchar2_table(517) := '616E222C20226D706C75732D7265766965772D6D65746122293B0A2020202020202020746869732E72657669657754657874203D20656C28227465787461726561222C20226D706C75732D7472616E73637269707420746578745F6669656C6420617065';
wwv_flow_imp.g_varchar2_table(518) := '782D6974656D2D7465787461726561222C207B20726F77733A20332C206D61786C656E6774683A204D41585F5452414E5343524950542C0A202020202020202020202020706C616365686F6C6465723A2074787428225452414E5343524950545F504C41';
wwv_flow_imp.g_varchar2_table(519) := '4345484F4C44455222292C2069643A20632E6974656D202B20225F5452414E53435249505422207D293B0A2020202020202020746869732E72657669657754657874426F78203D20656C2822646976222C20226D706C75732D7472616E7363726970742D';
wwv_flow_imp.g_varchar2_table(520) := '626F78222C206E756C6C2C205B0A202020202020202020202020656C28226C6162656C222C20226D706C75732D7472616E7363726970742D6C6162656C222C207B20666F723A20632E6974656D202B20225F5452414E534352495054222C20746578743A';
wwv_flow_imp.g_varchar2_table(521) := '2074787428225452414E5343524950542229207D292C20746869732E726576696577546578745D293B0A2020202020202020746869732E7265766965775469746C65203D20656C2822646976222C20226D706C75732D7265766965772D7469746C65222C';
wwv_flow_imp.g_varchar2_table(522) := '207B20746578743A2074787428225245564945575F5449544C452229207D293B0A2020202020202020746869732E6275696C64456469746F72287468293B0A2020202020202020746869732E726576696577203D20656C2822646976222C20226D706C75';
wwv_flow_imp.g_varchar2_table(523) := '732D726576696577222C206E756C6C2C205B0A202020202020202020202020746869732E7265766965775469746C652C0A202020202020202020202020746869732E706C617965722C0A202020202020202020202020746869732E70686F746F426F782C';
wwv_flow_imp.g_varchar2_table(524) := '0A202020202020202020202020656C2822646976222C20226D706C75732D7265766965772D626172222C206E756C6C2C205B746869732E7265766965774D6574615D292C0A202020202020202020202020746869732E72657669657754657874426F782C';
wwv_flow_imp.g_varchar2_table(525) := '0A202020202020202020202020656C2822646976222C20226D706C75732D616374696F6E73222C206E756C6C2C205B746869732E625573652C20746869732E62416761696E2C20746869732E62446973636172642C20746869732E61446F776E6C6F6164';
wwv_flow_imp.g_varchar2_table(526) := '5D290A20202020202020205D293B0A0A2020202020202020746869732E6C697374203D20656C2822756C222C20226D706C75732D6C69737422293B0A0A20202020202020205B746869732E746F702C20746869732E73746167652C20746869732E737474';
wwv_flow_imp.g_varchar2_table(527) := '426F782C20746869732E6D657465722C20746869732E6E6F746963652C20746869732E616374696F6E732C20746869732E7265766965772C20746869732E68696E742C20746869732E6C6973745D2E666F72456163682866756E6374696F6E2028782920';
wwv_flow_imp.g_varchar2_table(528) := '7B20722E617070656E644368696C642878293B207D293B0A0A20202020202020202F2F206576656E74730A2020202020202020746869732E6C616E6753656C2E6164644576656E744C697374656E657228226368616E6765222C2066756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(529) := '2829207B0A20202020202020202020202073656C662E6C616E67203D2073656C662E6C616E6753656C2E76616C75653B0A202020202020202020202020747279207B206C6F63616C53746F726167652E7365744974656D28226D706C75732D6C616E673A';
wwv_flow_imp.g_varchar2_table(530) := '22202B20632E6974656D2C2073656C662E6C616E67293B207D20636174636820286529207B202F2A206E6F74206B657074202A2F207D0A20202020202020207D293B0A2020202020202020746869732E625265636F72642E6164644576656E744C697374';
wwv_flow_imp.g_varchar2_table(531) := '656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E737461727428293B207D293B0A2020202020202020746869732E6250617573652E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E';
wwv_flow_imp.g_varchar2_table(532) := '202829207B2073656C662E746F67676C65506175736528293B207D293B0A2020202020202020746869732E6253746F702E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E73746F702829';
wwv_flow_imp.g_varchar2_table(533) := '3B207D293B0A2020202020202020746869732E625377697463682E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E73776974636843616D65726128293B207D293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(534) := '746869732E62436C6F73652E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E72656C6561736528293B2073656C662E7365745374617465282269646C6522293B207D293B0A2020202020';
wwv_flow_imp.g_varchar2_table(535) := '202020746869732E6246696C652E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E66696C652E636C69636B28293B207D293B0A2020202020202020746869732E66696C652E6164644576';
wwv_flow_imp.g_varchar2_table(536) := '656E744C697374656E657228226368616E6765222C2066756E6374696F6E202829207B206966202873656C662E66696C652E66696C65735B305D29207B2073656C662E75736546696C652873656C662E66696C652E66696C65735B305D293B207D207365';
wwv_flow_imp.g_varchar2_table(537) := '6C662E66696C652E76616C7565203D2022223B207D293B0A2020202020202020746869732E625573652E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E61636365707428293B207D293B';
wwv_flow_imp.g_varchar2_table(538) := '0A2020202020202020746869732E62416761696E2E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E646973636172642874727565293B207D293B0A2020202020202020746869732E6244';
wwv_flow_imp.g_varchar2_table(539) := '6973636172642E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E646973636172642866616C7365293B207D293B0A20202020202020202F2F20612070686F746F20697320646F776E6C6F';
wwv_flow_imp.g_varchar2_table(540) := '61646564206173206564697465640A2020202020202020746869732E61446F776E6C6F61642E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E20286529207B0A202020202020202020202020696620282173656C66';
wwv_flow_imp.g_varchar2_table(541) := '2E6564207C7C2073656C662E61446F776E6C6F61642E6D706C7573526561647929207B2073656C662E61446F776E6C6F61642E6D706C75735265616479203D2066616C73653B2072657475726E3B207D0A202020202020202020202020652E7072657665';
wwv_flow_imp.g_varchar2_table(542) := '6E7444656661756C7428293B0A20202020202020202020202073656C662E65644578706F727428292E7468656E2866756E6374696F6E202872657329207B0A202020202020202020202020202020206966202873656C662E646C55726C29207B2055524C';
wwv_flow_imp.g_varchar2_table(543) := '2E7265766F6B654F626A65637455524C2873656C662E646C55726C293B207D0A2020202020202020202020202020202073656C662E646C55726C203D2055524C2E6372656174654F626A65637455524C287265732E626C6F62293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(544) := '202020202020202073656C662E61446F776E6C6F61642E68726566203D2073656C662E646C55726C3B0A2020202020202020202020202020202073656C662E61446F776E6C6F61642E7365744174747269627574652822646F776E6C6F6164222C207365';
wwv_flow_imp.g_varchar2_table(545) := '6C662E70686F746F4E616D65287265732E626C6F622E7479706529293B0A2020202020202020202020202020202073656C662E61446F776E6C6F61642E6D706C75735265616479203D20747275653B0A2020202020202020202020202020202073656C66';
wwv_flow_imp.g_varchar2_table(546) := '2E61446F776E6C6F61642E636C69636B28293B0A2020202020202020202020207D293B0A20202020202020207D293B0A20202020202020202F2F206B6579626F6172642C207768696C652074686520666F63757320697320696E20746865206974656D3A';
wwv_flow_imp.g_varchar2_table(547) := '205020706175736573202F20726573756D65732C20532073746F70730A2020202020202020722E6164644576656E744C697374656E657228226B6579646F776E222C2066756E6374696F6E20286529207B0A20202020202020202020202069662028652E';
wwv_flow_imp.g_varchar2_table(548) := '6374726C4B6579207C7C20652E6D6574614B6579207C7C20652E616C744B6579207C7C202F5E2854455854415245417C494E5055547C53454C45435429242F2E7465737428652E7461726765742E7461674E616D652929207B2072657475726E3B207D0A';
wwv_flow_imp.g_varchar2_table(549) := '202020202020202020202020766172206B203D2028652E6B6579207C7C202222292E746F4C6F7765724361736528293B0A202020202020202020202020696620286B203D3D3D20227022202626202873656C662E7374617465203D3D3D20227265636F72';
wwv_flow_imp.g_varchar2_table(550) := '64696E6722207C7C2073656C662E7374617465203D3D3D2022706175736564222929207B20652E70726576656E7444656661756C7428293B2073656C662E746F67676C65506175736528293B207D0A202020202020202020202020696620286B203D3D3D';
wwv_flow_imp.g_varchar2_table(551) := '20227322202626202873656C662E7374617465203D3D3D20227265636F7264696E6722207C7C2073656C662E7374617465203D3D3D2022706175736564222929207B20652E70726576656E7444656661756C7428293B2073656C662E73746F7028293B20';
wwv_flow_imp.g_varchar2_table(552) := '7D0A20202020202020207D293B0A0A2020202020202020746869732E72656E6465724C69737428293B0A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(553) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D207374617465202620646973706C61790A202020205265636F726465722E70726F746F747970652E7365745374617465203D2066756E6374696F6E20287329207B0A2020202020202020746869732E';
wwv_flow_imp.g_varchar2_table(554) := '7374617465203D20733B0A2020202020202020746869732E726F6F742E7365744174747269627574652822646174612D7374617465222C2073293B0A2020202020202020746869732E73796E6328293B0A202020207D3B0A0A202020205265636F726465';
wwv_flow_imp.g_varchar2_table(555) := '722E70726F746F747970652E7365744B696E64203D2066756E6374696F6E20286B29207B0A202020202020202069662028746869732E737461746520213D3D202269646C6522207C7C20746869732E6B696E64203D3D3D206B207C7C20746869732E6B69';
wwv_flow_imp.g_varchar2_table(556) := '6E64732E696E6465784F66286B29203C203029207B2072657475726E3B207D0A2020202020202020746869732E6B696E64203D206B3B0A2020202020202020746869732E73796E6328293B0A202020207D3B0A0A202020205265636F726465722E70726F';
wwv_flow_imp.g_varchar2_table(557) := '746F747970652E66756C6C203D2066756E6374696F6E202829207B2072657475726E20746869732E6974656D732E6C656E677468203E3D204D6174682E6D617828312C20746869732E6366672E6D6178436F756E74207C7C2031293B207D3B0A0A202020';
wwv_flow_imp.g_varchar2_table(558) := '202F2F207468652063616D6572612070696374757265206B6565707320697473206F776E2073686170653A20706F727472616974206F6E2070686F6E65732C206C616E647363617065206F6E206C6170746F70730A202020205265636F726465722E7072';
wwv_flow_imp.g_varchar2_table(559) := '6F746F747970652E6669745374616765203D2066756E6374696F6E2028772C206829207B0A20202020202020206966202821746869732E63616D6572612829207C7C202177207C7C20216829207B0A202020202020202020202020746869732E73746167';
wwv_flow_imp.g_varchar2_table(560) := '652E7374796C652E617370656374526174696F203D2022223B0A202020202020202020202020746869732E73746167652E7374796C652E6D61785769647468203D2022223B0A20202020202020202020202072657475726E3B0A20202020202020207D0A';
wwv_flow_imp.g_varchar2_table(561) := '2020202020202020746869732E73746167652E7374796C652E617370656374526174696F203D2077202B2022202F2022202B20683B0A2020202020202020746869732E73746167652E7374796C652E6D61785769647468203D202263616C632836307668';
wwv_flow_imp.g_varchar2_table(562) := '202A2022202B202877202F2068292E746F4669786564283429202B202229223B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73796E63203D2066756E6374696F6E202829207B0A20202020202020207661722073203D';
wwv_flow_imp.g_varchar2_table(563) := '20746869732E73746174652C2063203D20746869732E6366672C20726F203D20632E726561644F6E6C79207C7C20746869732E64697361626C65642C0A2020202020202020202020206C697665203D2073203D3D3D20226F70656E696E6722207C7C2073';
wwv_flow_imp.g_varchar2_table(564) := '203D3D3D2022726561647922207C7C2073203D3D3D2022636F756E74646F776E22207C7C2073203D3D3D20227265636F7264696E6722207C7C2073203D3D3D202270617573656422207C7C2073203D3D3D202273746F7070696E67222C0A202020202020';
wwv_flow_imp.g_varchar2_table(565) := '202020202020726F6C6C696E67203D2073203D3D3D20226F70656E696E6722207C7C2073203D3D3D2022636F756E74646F776E22207C7C2073203D3D3D20227265636F7264696E6722207C7C2073203D3D3D202270617573656422207C7C2073203D3D3D';
wwv_flow_imp.g_varchar2_table(566) := '202273746F7070696E67222C0A202020202020202020202020766964656F203D20746869732E6B696E64203D3D3D2022766964656F222C20696D616765203D20746869732E6B696E64203D3D3D2022696D616765222C2063616D203D20746869732E6361';
wwv_flow_imp.g_varchar2_table(567) := '6D65726128292C2073656C66203D20746869733B0A0A20202020202020202F2F207468652063616D657261206B696E64732073686172652074686520766964656F2073746167650A2020202020202020746869732E726F6F742E636C6173734C6973742E';
wwv_flow_imp.g_varchar2_table(568) := '746F67676C6528226D706C75732D2D766964656F222C2063616D293B0A2020202020202020746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D696D616765222C20696D616765293B0A202020202020202074686973';
wwv_flow_imp.g_varchar2_table(569) := '2E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D617564696F222C202163616D293B0A2020202020202020746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D64697361626C6564222C20';
wwv_flow_imp.g_varchar2_table(570) := '746869732E64697361626C6564293B0A2020202020202020746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D6D6972726F72222C2063616D20262620746869732E666163696E67203D3D3D20227573657222202626';
wwv_flow_imp.g_varchar2_table(571) := '20746869732E68617328226D6972726F722229293B0A20202020202020204F626A6563742E6B65797328746869732E73656742746E73292E666F72456163682866756E6374696F6E20286B29207B0A20202020202020202020202073656C662E73656742';
wwv_flow_imp.g_varchar2_table(572) := '746E735B6B5D2E7365744174747269627574652822617269612D70726573736564222C20537472696E67286B203D3D3D2073656C662E6B696E6429293B0A20202020202020202020202073656C662E73656742746E735B6B5D2E64697361626C6564203D';
wwv_flow_imp.g_varchar2_table(573) := '207320213D3D202269646C6522207C7C2073656C662E64697361626C65643B0A20202020202020207D293B0A202020202020202073686F7728746869732E6C616E6753656C2C2021726F20262620746869732E7472616E73637269626573282920262620';
wwv_flow_imp.g_varchar2_table(574) := '746869732E6C616E67732E6C656E677468203E2031202626202121746869732E5352293B0A2020202020202020746869732E6C616E6753656C2E64697361626C6564203D207320213D3D202269646C6522202626207320213D3D20227265616479223B0A';
wwv_flow_imp.g_varchar2_table(575) := '0A202020202020202076617220737461747573203D207B206F70656E696E673A2074787428225354415254494E4722292C2072656164793A207478742822524541445922292C20636F756E74646F776E3A207478742822524541445922292C207265636F';
wwv_flow_imp.g_varchar2_table(576) := '7264696E673A2074787428225245434F5244494E4722292C0A20202020202020202020202020202020202020202020207061757365643A20747874282250415553454422292C2073746F7070696E673A20747874282246494E495348494E4722292C2072';
wwv_flow_imp.g_varchar2_table(577) := '65766965773A20747874282252455649455722292C0A202020202020202020202020202020202020202020202075706C6F6164696E673A20632E7472616E736372697074696F6E203D3D3D20225345525645522220262620746869732E75706C6F616469';
wwv_flow_imp.g_varchar2_table(578) := '6E67417564696F203F2074787428225452414E5343524942494E475F5345525645522229203A20747874282255504C4F4144494E472229207D5B735D207C7C2022223B0A2020202020202020746869732E7374617475732E74657874436F6E74656E7420';
wwv_flow_imp.g_varchar2_table(579) := '3D207374617475733B0A2020202020202020746869732E7374617475732E636C6173734E616D65203D20226D706C75732D737461747573206D706C75732D7374617475732D2D22202B20733B0A202020202020202073686F7728746869732E7374617475';
wwv_flow_imp.g_varchar2_table(580) := '732C202121737461747573293B0A202020202020202073686F7728746869732E746F702C2021726F2026262028746869732E6B696E64732E6C656E677468203E2031207C7C202121737461747573207C7C2021746869732E6C616E6753656C2E68696464';
wwv_flow_imp.g_varchar2_table(581) := '656E29293B0A0A202020202020202073686F7728746869732E73746167652C2021726F202626206C697665293B0A202020202020202073686F7728746869732E766964656F2C2063616D293B0A202020202020202073686F7728746869732E63616E7661';
wwv_flow_imp.g_varchar2_table(582) := '732C202163616D20262620746869732E68617328226C6576656C4D657465722229293B0A202020202020202073686F7728746869732E6C6576656C2C20766964656F20262620746869732E68617328226C6576656C4D6574657222292026262074686973';
wwv_flow_imp.g_varchar2_table(583) := '2E77697468536F756E642829293B0A202020202020202073686F7728746869732E73746167652E717565727953656C6563746F7228222E6D706C75732D72656322292C2021696D616765293B0A202020202020202073686F7728746869732E737474426F';
wwv_flow_imp.g_varchar2_table(584) := '782C2021726F20262620746869732E7472616E736372696265732829202626202873203D3D3D20227265636F7264696E6722207C7C2073203D3D3D202270617573656422207C7C2073203D3D3D202273746F7070696E6722292026262021212874686973';
wwv_flow_imp.g_varchar2_table(585) := '2E73747446696E616C456C2E74657874436F6E74656E74207C7C20746869732E737474496E746572696D456C2E74657874436F6E74656E74207C7C20746869732E73747429293B0A20202020202020202F2F20746865206D65746572206B656570732069';
wwv_flow_imp.g_varchar2_table(586) := '747320706C6163652066726F6D20746865206D6F6D656E74205265636F726420697320707265737365642C20736F206E6F7468696E67206A756D70730A202020202020202073686F7728746869732E6D657465722C2021726F20262620726F6C6C696E67';
wwv_flow_imp.g_varchar2_table(587) := '293B0A0A20202020202020207661722063616E5265636F7264203D20746869732E737570706F727465642026262021726F2026262021746869732E66756C6C28293B0A202020202020202073686F7728746869732E616374696F6E732C2021726F202626';
wwv_flow_imp.g_varchar2_table(588) := '207320213D3D202272657669657722202626207320213D3D202275706C6F6164696E6722293B0A202020202020202073686F7728746869732E625265636F72642C2063616E5265636F7264202626202873203D3D3D202269646C6522207C7C2073203D3D';
wwv_flow_imp.g_varchar2_table(589) := '3D202272656164792229293B0A202020202020202069662028696D61676529207B0A20202020202020202020202073657443746C28746869732E625265636F72642C202266612D63616D657261222C2073203D3D3D2022726561647922203F2074787428';
wwv_flow_imp.g_varchar2_table(590) := '22434150545552452229203A20747874282254414B455F50484F544F2229293B0A20202020202020207D20656C7365207B0A20202020202020202020202073657443746C28746869732E625265636F72642C207320213D3D202272656164792220262620';
wwv_flow_imp.g_varchar2_table(591) := '766964656F203F202266612D766964656F2D63616D65726122203A2022726563222C2073203D3D3D2022726561647922203F20747874282253544152542229203A20766964656F203F2074787428224F50454E5F43414D4552412229203A207478742822';
wwv_flow_imp.g_varchar2_table(592) := '5245434F52442229293B0A20202020202020207D0A2020202020202020746869732E625265636F72642E636C6173734C6973742E746F67676C6528226D706C75732D62746E2D2D73687574746572222C20696D6167652026262073203D3D3D2022726561';
wwv_flow_imp.g_varchar2_table(593) := '647922293B0A202020202020202073686F7728746869732E6250617573652C20746869732E68617328227061757365222920262620726F6C6C696E67293B0A2020202020202020746869732E6250617573652E64697361626C6564203D207320213D3D20';
wwv_flow_imp.g_varchar2_table(594) := '227265636F7264696E6722202626207320213D3D2022706175736564223B0A202020202020202073657443746C28746869732E6250617573652C2073203D3D3D202270617573656422203F2022706C617922203A20227061757365222C2073203D3D3D20';
wwv_flow_imp.g_varchar2_table(595) := '2270617573656422203F207478742822524553554D452229203A20747874282250415553452229293B0A2020202020202020746869732E6250617573652E636C6173734C6973742E746F67676C6528226D706C75732D62746E2D2D7072696D617279222C';
wwv_flow_imp.g_varchar2_table(596) := '2073203D3D3D2022706175736564222026262021746869732E6250617573652E6D706C75735468656D65293B0A202020202020202073686F7728746869732E6253746F702C20726F6C6C696E67293B0A2020202020202020746869732E6253746F702E64';
wwv_flow_imp.g_varchar2_table(597) := '697361626C6564203D2073203D3D3D202273746F7070696E67223B0A202020202020202073657443746C28746869732E6253746F702C202273746F70222C2073203D3D3D20226F70656E696E6722207C7C2073203D3D3D2022636F756E74646F776E2220';
wwv_flow_imp.g_varchar2_table(598) := '3F20747874282243414E43454C2229203A20747874282253544F502229293B0A202020202020202073686F7728746869732E625377697463682C2063616D2026262073203D3D3D202272656164792220262620746869732E686173282273776974636843';
wwv_flow_imp.g_varchar2_table(599) := '616D657261222920262620746869732E63616D65726173203E2031293B0A202020202020202073686F7728746869732E62436C6F73652C2073203D3D3D2022726561647922293B0A202020202020202073686F7728746869732E6246696C652C2021726F';
wwv_flow_imp.g_varchar2_table(600) := '2026262021746869732E66756C6C28292026262073203D3D3D202269646C65222026262028746869732E686173282275706C6F61642229207C7C2021746869732E737570706F7274656429293B0A20202020202020207661722070686F746F203D202121';
wwv_flow_imp.g_varchar2_table(601) := '746869732E65643B0A202020202020202073686F7728746869732E7265766965772C2073203D3D3D202272657669657722293B0A202020202020202073686F7728746869732E706C617965722C202170686F746F293B0A202020202020202073686F7728';
wwv_flow_imp.g_varchar2_table(602) := '746869732E70686F746F426F782C2070686F746F293B0A2020202020202020746869732E7265766965775469746C652E74657874436F6E74656E74203D2070686F746F203F20747874282250484F544F5F5449544C452229203A20747874282252455649';
wwv_flow_imp.g_varchar2_table(603) := '45575F5449544C4522293B0A202020202020202073686F7728746869732E72657669657754657874426F782C202170686F746F2026262028746869732E7472616E736372696265732829207C7C202121746869732E726576696577546578742E76616C75';
wwv_flow_imp.g_varchar2_table(604) := '6529293B0A20202020202020202F2F2061207265636F7264696E67206F76657220746865206C696D69742063616E206F6E6C7920626520646F776E6C6F616465643B2061206661696C65642075706C6F61642063616E2062652074726965642061676169';
wwv_flow_imp.g_varchar2_table(605) := '6E0A2020202020202020746869732E625573652E64697361626C6564203D202121746869732E746F6F426967207C7C202121746869732E6564576F726B696E673B0A202020202020202073657443746C28746869732E625573652C20746869732E666169';
wwv_flow_imp.g_varchar2_table(606) := '6C6564203F202266612D7265667265736822203A202266612D636865636B222C20746869732E6661696C6564203F20747874282252455452592229203A2070686F746F203F2074787428225553455F50484F544F2229203A207478742822555345222929';
wwv_flow_imp.g_varchar2_table(607) := '3B0A202020202020202073657443746C28746869732E62416761696E2C2070686F746F203F202266612D63616D65726122203A202266612D756E646F222C2070686F746F203F207478742822524554414B452229203A207478742822414741494E222929';
wwv_flow_imp.g_varchar2_table(608) := '3B0A202020202020202073686F7728746869732E62416761696E2C202170686F746F207C7C20746869732E737570706F72746564293B0A202020202020202073686F7728746869732E61446F776E6C6F61642C20746869732E6861732822646F776E6C6F';
wwv_flow_imp.g_varchar2_table(609) := '61642229207C7C202121746869732E6661696C6564207C7C202121746869732E746F6F426967293B0A2020202020202020696620282163616D29207B20746869732E666974537461676528302C2030293B207D0A20202020202020206966202874686973';
wwv_flow_imp.g_varchar2_table(610) := '2E6250617573652E6D706C75735468656D6529207B20746869732E6250617573652E636C6173734C6973742E746F67676C652822742D427574746F6E2D2D686F74222C2073203D3D3D202270617573656422293B207D0A0A202020202020202076617220';
wwv_flow_imp.g_varchar2_table(611) := '68696E74203D2022223B0A20202020202020206966202821726F2026262073203D3D3D202269646C652229207B0A20202020202020202020202069662028746869732E66756C6C282929207B0A2020202020202020202020202020202068696E74203D20';
wwv_flow_imp.g_varchar2_table(612) := '632E6D6178436F756E74203E2031203F2074787428224D41585F434F554E54222C20632E6D6178436F756E7429203A2074787428224D41585F434F554E545F4F4E4522293B0A2020202020202020202020207D20656C7365206966202821746869732E73';
wwv_flow_imp.g_varchar2_table(613) := '7570706F7274656429207B0A2020202020202020202020202020202068696E74203D2074787428224E4F545F535550504F5254454422293B0A2020202020202020202020207D20656C73652069662028696D61676529207B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(614) := '202020202068696E74203D2074787428224C494D49545F48494E54222C20666D74427974657328632E6D6178427974657329293B0A2020202020202020202020207D20656C7365207B0A202020202020202020202020202020207661722071203D207468';
wwv_flow_imp.g_varchar2_table(615) := '69732E7175616C69747928292C0A20202020202020202020202020202020202020206B627073203D2028746869732E77697468536F756E642829203F20746869732E617564696F4B6270732829203A203029202B2028766964656F203F20712E76696465';
wwv_flow_imp.g_varchar2_table(616) := '6F4B627073203A2030292C0A202020202020202020202020202020202020202073656373203D206B627073203F20632E6D61784279746573202A2038202F20286B627073202A203130303029203A20302C0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(617) := '20206C696D6974203D20632E6D61784475726174696F6E203F2074787428224C494D49545F48494E545F54494D45222C20666D7454696D6528632E6D61784475726174696F6E292C20666D74427974657328632E6D617842797465732929203A20747874';
wwv_flow_imp.g_varchar2_table(618) := '28224C494D49545F48494E54222C20666D74427974657328632E6D6178427974657329293B0A2020202020202020202020202020202068696E74203D206C696D6974202B202873656373202626202821632E6D61784475726174696F6E207C7C20736563';
wwv_flow_imp.g_varchar2_table(619) := '73203C20632E6D61784475726174696F6E29203F202220C2B72022202B2074787428224341504143495459222C20666D745370616E28736563732929203A202222293B0A2020202020202020202020207D0A20202020202020207D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(620) := '746869732E68696E742E74657874436F6E74656E74203D2068696E743B0A202020202020202073686F7728746869732E68696E742C20212168696E74293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E736179203D20';
wwv_flow_imp.g_varchar2_table(621) := '66756E6374696F6E2028746578742C207479706529207B0A2020202020202020746869732E6E6F746963652E74657874436F6E74656E74203D2022223B0A2020202020202020696620287465787429207B0A202020202020202020202020746869732E6E';
wwv_flow_imp.g_varchar2_table(622) := '6F746963652E617070656E644368696C6428666149636F6E2874797065203D3D3D20226572726F7222203F202266612D6578636C616D6174696F6E2D636972636C6522203A2074797065203D3D3D20227761726E22203F202266612D6578636C616D6174';
wwv_flow_imp.g_varchar2_table(623) := '696F6E2D747269616E676C6522203A202266612D696E666F2D636972636C652229293B0A202020202020202020202020746869732E6E6F746963652E617070656E644368696C6428656C28227370616E222C206E756C6C2C207B20746578743A20746578';
wwv_flow_imp.g_varchar2_table(624) := '74207D29293B0A20202020202020207D0A2020202020202020746869732E6E6F746963652E636C6173734E616D65203D20226D706C75732D6E6F7469636522202B202874797065203F2022206D706C75732D6E6F746963652D2D22202B2074797065203A';
wwv_flow_imp.g_varchar2_table(625) := '202222293B0A20202020202020202F2F206572726F727320616E64207761726E696E677320696E7465727275707420612073637265656E207265616465722C20696E666F726D6174696F6E2077616974730A2020202020202020746869732E6E6F746963';
wwv_flow_imp.g_varchar2_table(626) := '652E7365744174747269627574652822726F6C65222C2074797065203D3D3D20226572726F7222207C7C2074797065203D3D3D20227761726E22203F2022616C65727422203A202273746174757322293B0A202020202020202073686F7728746869732E';
wwv_flow_imp.g_varchar2_table(627) := '6E6F746963652C20212174657874293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E66697265203D2066756E6374696F6E20286E616D652C206461746129207B0A2020202020202020617065782E6576656E742E7472';
wwv_flow_imp.g_varchar2_table(628) := '696767657228746869732E696E7075742C20226D65646961706C757322202B206E616D652C20242E657874656E64287B206974656D3A20746869732E6366672E6974656D207D2C2064617461207C7C207B7D29293B0A202020207D3B0A0A202020205265';
wwv_flow_imp.g_varchar2_table(629) := '636F726465722E70726F746F747970652E666F6375734E657874203D2066756E6374696F6E202829207B0A202020202020202076617220746172676574203D2021746869732E625265636F72642E68696464656E203F20746869732E625265636F726420';
wwv_flow_imp.g_varchar2_table(630) := '3A20746869732E6C6973742E717565727953656C6563746F7228222E6D706C75732D726F773A6C6173742D6368696C6420627574746F6E22293B0A20202020202020206966202874617267657429207B207461726765742E666F63757328293B207D0A20';
wwv_flow_imp.g_varchar2_table(631) := '2020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D20646576696365730A202020205265636F726465722E';
wwv_flow_imp.g_varchar2_table(632) := '70726F746F747970652E636F6E73747261696E7473203D2066756E6374696F6E202829207B0A20202020202020207661722071203D20746869732E7175616C69747928292C2061203D20746869732E617564696F4F7074732C20617564696F203D206661';
wwv_flow_imp.g_varchar2_table(633) := '6C73652C20766964656F203D2066616C73653B0A202020202020202069662028746869732E77697468536F756E64282929207B0A202020202020202020202020617564696F203D207B0A202020202020202020202020202020206563686F43616E63656C';
wwv_flow_imp.g_varchar2_table(634) := '6C6174696F6E3A20612E696E6465784F6628226563686F43616E63656C6C6174696F6E2229203E3D20302C0A202020202020202020202020202020206E6F6973655375707072657373696F6E3A20612E696E6465784F6628226E6F697365537570707265';
wwv_flow_imp.g_varchar2_table(635) := '7373696F6E2229203E3D20302C0A202020202020202020202020202020206175746F4761696E436F6E74726F6C3A20612E696E6465784F6628226175746F4761696E436F6E74726F6C2229203E3D20300A2020202020202020202020207D3B0A20202020';
wwv_flow_imp.g_varchar2_table(636) := '202020202020202069662028612E696E6465784F6628226D6F6E6F2229203E3D203029207B20617564696F2E6368616E6E656C436F756E74203D207B20696465616C3A2031207D3B207D0A20202020202020207D0A202020202020202069662028746869';
wwv_flow_imp.g_varchar2_table(637) := '732E6B696E64203D3D3D2022766964656F2229207B0A202020202020202020202020766964656F203D207B0A20202020202020202020202020202020666163696E674D6F64653A207B20696465616C3A20746869732E666163696E67207D2C0A20202020';
wwv_flow_imp.g_varchar2_table(638) := '2020202020202020202020206865696768743A207B20696465616C3A20712E766964656F486569676874207D2C0A2020202020202020202020202020202077696474683A207B20696465616C3A204D6174682E726F756E6428712E766964656F48656967';
wwv_flow_imp.g_varchar2_table(639) := '6874202A203136202F203929207D2C0A202020202020202020202020202020206672616D65526174653A207B20696465616C3A20712E6670732C206D61783A20712E667073207D0A2020202020202020202020207D3B0A20202020202020207D20656C73';
wwv_flow_imp.g_varchar2_table(640) := '652069662028746869732E6B696E64203D3D3D2022696D6167652229207B0A2020202020202020202020202F2F2070686F746F733A20617320736861727020617320746865206F7574707574206E656564732C20696E207468652063616D657261277320';
wwv_flow_imp.g_varchar2_table(641) := '6F776E20343A332073686170650A2020202020202020202020207661722073696465203D204D6174682E6D617828313238302C20746869732E6366672E696D6167654D617853696465207C7C2031393230293B0A20202020202020202020202076696465';
wwv_flow_imp.g_varchar2_table(642) := '6F203D207B20666163696E674D6F64653A207B20696465616C3A20746869732E666163696E67207D2C2077696474683A207B20696465616C3A2073696465207D2C206865696768743A207B20696465616C3A204D6174682E726F756E642873696465202A';
wwv_flow_imp.g_varchar2_table(643) := '2033202F203429207D207D3B0A20202020202020207D0A202020202020202072657475726E207B20617564696F3A20617564696F2C20766964656F3A20766964656F207D3B0A202020207D3B0A0A202020205265636F726465722E70726F746F74797065';
wwv_flow_imp.g_varchar2_table(644) := '2E6F70656E203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869733B0A2020202020202020746869732E736179282222293B0A2020202020202020746869732E63616E63656C6C6564203D2066616C73653B';
wwv_flow_imp.g_varchar2_table(645) := '0A2020202020202020746869732E74696D65722E74657874436F6E74656E74203D2022303A3030223B0A2020202020202020746869732E6D6574657246696C6C2E7374796C652E7769647468203D202230223B0A2020202020202020746869732E6D6574';
wwv_flow_imp.g_varchar2_table(646) := '6572546578742E74657874436F6E74656E74203D2074787428224F46222C20666D7442797465732830292C20666D74427974657328746869732E6366672E6D6178427974657329293B0A2020202020202020746869732E736574537461746528226F7065';
wwv_flow_imp.g_varchar2_table(647) := '6E696E6722293B0A2020202020202020617564696F53657373696F6E2822706C61792D616E642D7265636F726422293B0A202020202020202072657475726E206E6176696761746F722E6D65646961446576696365732E676574557365724D6564696128';
wwv_flow_imp.g_varchar2_table(648) := '746869732E636F6E73747261696E74732829292E7468656E2866756E6374696F6E202873747265616D29207B0A2020202020202020202020206966202873656C662E63616E63656C6C656429207B0A202020202020202020202020202020207374726561';
wwv_flow_imp.g_varchar2_table(649) := '6D2E676574547261636B7328292E666F72456163682866756E6374696F6E20287429207B20742E73746F7028293B207D293B0A202020202020202020202020202020207468726F77206E6577204572726F72282263616E63656C6C656422293B0A202020';
wwv_flow_imp.g_varchar2_table(650) := '2020202020202020207D0A20202020202020202020202073656C662E73747265616D203D2073747265616D3B0A2020202020202020202020202F2F20612063616C6C2C207468652073637265656E206C6F636B696E67206F7220616E20756E706C756767';
wwv_flow_imp.g_varchar2_table(651) := '65642064657669636520656E64732074686520747261636B730A20202020202020202020202073747265616D2E676574547261636B7328292E666F72456163682866756E6374696F6E20287429207B20742E6164644576656E744C697374656E65722822';
wwv_flow_imp.g_varchar2_table(652) := '656E646564222C2066756E6374696F6E202829207B2073656C662E747261636B456E6465642873747265616D293B207D293B207D293B0A2020202020202020202020206966202873656C662E63616D657261282929207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(653) := '20202020766172207374203D2073747265616D2E676574566964656F547261636B7328295B305D2026262073747265616D2E676574566964656F547261636B7328295B305D2E67657453657474696E6773203F2073747265616D2E676574566964656F54';
wwv_flow_imp.g_varchar2_table(654) := '7261636B7328295B305D2E67657453657474696E67732829203A207B7D3B0A2020202020202020202020202020202073656C662E66697453746167652873742E77696474682C2073742E686569676874293B0A2020202020202020202020202020202073';
wwv_flow_imp.g_varchar2_table(655) := '656C662E766964656F2E7372634F626A656374203D2073747265616D3B0A2020202020202020202020202020202073656C662E766964656F2E636F6E74726F6C73203D2066616C73653B0A2020202020202020202020202020202073656C662E76696465';
wwv_flow_imp.g_varchar2_table(656) := '6F2E706C617928292E63617463682866756E6374696F6E202829207B202F2A206175746F706C617920626C6F636B6564202D207374617973206F6E206669727374206672616D65202A2F207D293B0A2020202020202020202020207D0A20202020202020';
wwv_flow_imp.g_varchar2_table(657) := '20202020206966202873747265616D2E676574417564696F547261636B7328292E6C656E67746829207B0A2020202020202020202020202020202073656C662E6D65746572537461727428293B0A202020202020202020202020202020202F2F20694F53';
wwv_flow_imp.g_varchar2_table(658) := '206D7574657320746865206D6963726F70686F6E65207768656E20736F6D657468696E6720656C73652074616B65732069742028612063616C6C2C20536972692C20737065656368207265636F676E6974696F6E206F6E20612068656164736574290A20';
wwv_flow_imp.g_varchar2_table(659) := '20202020202020202020202020202073747265616D2E676574417564696F547261636B7328292E666F72456163682866756E6374696F6E20287429207B20742E6164644576656E744C697374656E657228226D757465222C2066756E6374696F6E202829';
wwv_flow_imp.g_varchar2_table(660) := '207B2073656C662E736F756E644C6F73742873747265616D293B207D293B207D293B0A2020202020202020202020207D0A20202020202020202020202073656C662E636F756E7443616D6572617328293B0A20202020202020207D292E63617463682866';
wwv_flow_imp.g_varchar2_table(661) := '756E6374696F6E20286529207B0A2020202020202020202020206966202873656C662E63616E63656C6C656429207B207468726F7720653B207D0A20202020202020202020202073656C662E72656C6561736528293B0A20202020202020202020202073';
wwv_flow_imp.g_varchar2_table(662) := '656C662E7365745374617465282269646C6522293B0A202020202020202020202020766172206E6F74416C6C6F776564203D20652026262028652E6E616D65203D3D3D20224E6F74416C6C6F7765644572726F7222207C7C20652E6E616D65203D3D3D20';
wwv_flow_imp.g_varchar2_table(663) := '2253656375726974794572726F7222292C0A202020202020202020202020202020206E6F446576696365203D20652026262028652E6E616D65203D3D3D20224E6F74466F756E644572726F7222207C7C20652E6E616D65203D3D3D20224F766572636F6E';
wwv_flow_imp.g_varchar2_table(664) := '73747261696E65644572726F7222293B0A20202020202020202020202073656C662E736179286E6F74416C6C6F776564203F2074787428224E4F5F5045524D495353494F4E2229203A206E6F446576696365203F2074787428224E4F5F44455649434522';
wwv_flow_imp.g_varchar2_table(665) := '29203A20286520262620652E6D65737361676529207C7C2074787428224E4F545F535550504F5254454422292C20226572726F7222293B0A20202020202020202020202073656C662E6669726528226572726F72222C207B20726561736F6E3A20652026';
wwv_flow_imp.g_varchar2_table(666) := '2620652E6E616D652C206D6573736167653A206520262620652E6D657373616765207D293B0A2020202020202020202020207468726F7720653B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970';
wwv_flow_imp.g_varchar2_table(667) := '652E747261636B456E646564203D2066756E6374696F6E202873747265616D29207B0A20202020202020206966202873747265616D20213D3D20746869732E73747265616D29207B2072657475726E3B207D0A202020202020202069662028746869732E';
wwv_flow_imp.g_varchar2_table(668) := '7374617465203D3D3D20227265636F7264696E6722207C7C20746869732E7374617465203D3D3D20227061757365642229207B0A202020202020202020202020746869732E7361792874787428224445564943455F454E44454422292C20227761726E22';
wwv_flow_imp.g_varchar2_table(669) := '293B0A202020202020202020202020746869732E73746F70282264657669636522293B0A20202020202020207D20656C73652069662028746869732E7374617465203D3D3D2022726561647922207C7C20746869732E7374617465203D3D3D2022636F75';
wwv_flow_imp.g_varchar2_table(670) := '6E74646F776E2229207B0A202020202020202020202020636C656172496E74657276616C28746869732E636454696D6572293B0A202020202020202020202020746869732E636F756E74646F776E2E74657874436F6E74656E74203D2022223B0A202020';
wwv_flow_imp.g_varchar2_table(671) := '202020202020202020746869732E72656C6561736528293B0A202020202020202020202020746869732E7365745374617465282269646C6522293B0A202020202020202020202020746869732E7361792874787428224445564943455F454E4445442229';
wwv_flow_imp.g_varchar2_table(672) := '2C20227761726E22293B0A20202020202020207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E72656C65617365203D2066756E6374696F6E202829207B0A202020202020202076617220686164203D20212174686973';
wwv_flow_imp.g_varchar2_table(673) := '2E73747265616D3B0A202020202020202069662028746869732E73747265616D29207B20746869732E73747265616D2E676574547261636B7328292E666F72456163682866756E6374696F6E20287429207B20742E73746F7028293B207D293B207D0A20';
wwv_flow_imp.g_varchar2_table(674) := '20202020202020746869732E73747265616D203D206E756C6C3B0A2020202020202020746869732E766964656F2E7372634F626A656374203D206E756C6C3B0A2020202020202020746869732E6D6574657253746F7028293B0A20202020202020202F2F';
wwv_flow_imp.g_varchar2_table(675) := '206261636B20746F206E6F726D616C20706C61796261636B2C20736F207468652072657669657720706C61796572206973206865617264206F6E20746865206C6F7564737065616B65722028694F53290A20202020202020206966202868616429207B20';
wwv_flow_imp.g_varchar2_table(676) := '617564696F53657373696F6E2822706C61796261636B22293B207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73776974636843616D657261203D2066756E6374696F6E202829207B0A202020202020202076617220';
wwv_flow_imp.g_varchar2_table(677) := '73656C66203D20746869733B0A202020202020202069662028746869732E737461746520213D3D202272656164792229207B2072657475726E3B207D0A2020202020202020746869732E666163696E67203D20746869732E666163696E67203D3D3D2022';
wwv_flow_imp.g_varchar2_table(678) := '7573657222203F2022656E7669726F6E6D656E7422203A202275736572223B0A2020202020202020746869732E72656C6561736528293B0A2020202020202020746869732E6F70656E28292E7468656E2866756E6374696F6E202829207B2073656C662E';
wwv_flow_imp.g_varchar2_table(679) := '73657453746174652822726561647922293B207D292E63617463682866756E6374696F6E202829207B202F2A206D6573736167652073686F776E202A2F207D293B0A202020207D3B0A0A202020202F2F20536166617269206C69737473206F6E6C79206F';
wwv_flow_imp.g_varchar2_table(680) := '6E652063616D65726120756E74696C207468652070616765206D617920757365207468652063616D6572613A20636F756E74207468656D20616761696E206F6E6365206974206D61790A202020205265636F726465722E70726F746F747970652E636F75';
wwv_flow_imp.g_varchar2_table(681) := '6E7443616D65726173203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869733B0A202020202020202069662028216E6176696761746F722E6D6564696144657669636573207C7C20216E6176696761746F72';
wwv_flow_imp.g_varchar2_table(682) := '2E6D65646961446576696365732E656E756D65726174654465766963657329207B2072657475726E3B207D0A20202020202020206E6176696761746F722E6D65646961446576696365732E656E756D65726174654465766963657328292E7468656E2866';
wwv_flow_imp.g_varchar2_table(683) := '756E6374696F6E20286C69737429207B0A20202020202020202020202073656C662E63616D65726173203D206C6973742E66696C7465722866756E6374696F6E20286429207B2072657475726E20642E6B696E64203D3D3D2022766964656F696E707574';
wwv_flow_imp.g_varchar2_table(684) := '223B207D292E6C656E6774683B0A20202020202020202020202073656C662E73796E6328293B0A20202020202020207D292E63617463682866756E6374696F6E202829207B202F2A206B6565702074686520636F756E74202A2F207D293B0A202020207D';
wwv_flow_imp.g_varchar2_table(685) := '3B0A0A202020202F2F206E6F20736F756E64207265616368657320746865207265636F7264696E6720286D6963726F70686F6E65206D75746564206279207468652073797374656D2C206F722073696C656E74293A2073617920736F207768696C652074';
wwv_flow_imp.g_varchar2_table(686) := '686572652069732074696D650A202020205265636F726465722E70726F746F747970652E736F756E644C6F7374203D2066756E6374696F6E202873747265616D29207B0A2020202020202020696620282873747265616D2026262073747265616D20213D';
wwv_flow_imp.g_varchar2_table(687) := '3D20746869732E73747265616D29207C7C20746869732E736F756E645761726E6564207C7C2028746869732E737461746520213D3D20227265636F7264696E672220262620746869732E737461746520213D3D2022706175736564222026262074686973';
wwv_flow_imp.g_varchar2_table(688) := '2E737461746520213D3D20227265616479222929207B2072657475726E3B207D0A2020202020202020746869732E736F756E645761726E6564203D20747275653B0A2020202020202020746869732E7361792874787428224E4F5F534F554E4422292C20';
wwv_flow_imp.g_varchar2_table(689) := '227761726E22293B0A2020202020202020746869732E6669726528227761726E696E67222C207B20726561736F6E3A20226E6F736F756E64222C207365636F6E64733A20746869732E7365636F6E6473203F20746869732E7365636F6E64732829203A20';
wwv_flow_imp.g_varchar2_table(690) := '30207D293B0A202020207D3B0A0A202020202F2F204C6576656C206D657465722C2077617665666F726D20616E642073696C656E636520636865636B202857656220417564696F292E2054686520417564696F436F6E74657874206973206D616465206F';
wwv_flow_imp.g_varchar2_table(691) := '6E636520746865206D6963726F70686F6E65206973206F70656E3A0A202020202F2F206D616465206265666F72652C20694F532063616E206B65657020746865206F6C6420617564696F20726F7574652028652E672E2077697468206865616470686F6E';
wwv_flow_imp.g_varchar2_table(692) := '657320636F6E6E65637465642920616E6420746865207265636F7264696E672073746179730A202020202F2F2073696C656E742E205768696C65206120706167652063617074757265732C2053616661726920616E64204368726F6D65206C6574206974';
wwv_flow_imp.g_varchar2_table(693) := '20737461727420776974686F757420616E6F74686572207461702E0A202020205265636F726465722E70726F746F747970652E6D657465725374617274203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869';
wwv_flow_imp.g_varchar2_table(694) := '732C204143203D2077696E646F772E417564696F436F6E74657874207C7C2077696E646F772E7765626B6974417564696F436F6E746578742C0A202020202020202020202020747261636B203D20746869732E73747265616D20262620746869732E7374';
wwv_flow_imp.g_varchar2_table(695) := '7265616D2E676574417564696F547261636B7328295B305D2C2072617465203D20747261636B20262620747261636B2E67657453657474696E6773203F20747261636B2E67657453657474696E677328292E73616D706C6552617465203A20303B0A2020';
wwv_flow_imp.g_varchar2_table(696) := '20202020202069662028214143207C7C2021747261636B29207B2072657475726E3B207D0A2020202020202020747279207B0A202020202020202020202020747279207B20746869732E6163203D206E65772041432872617465203F207B2073616D706C';
wwv_flow_imp.g_varchar2_table(697) := '65526174653A2072617465207D203A20756E646566696E6564293B207D2063617463682028653129207B20746869732E6163203D206E657720414328293B207D0A20202020202020202020202069662028746869732E61632E7374617465203D3D3D2022';
wwv_flow_imp.g_varchar2_table(698) := '73757370656E6465642229207B20746869732E61632E726573756D6528292E63617463682866756E6374696F6E202829207B202F2A207374617973207374696C6C202A2F207D293B207D0A20202020202020202020202076617220737263203D20746869';
wwv_flow_imp.g_varchar2_table(699) := '732E61632E6372656174654D6564696153747265616D536F7572636528746869732E73747265616D293B0A202020202020202020202020746869732E616E616C79736572203D20746869732E61632E637265617465416E616C7973657228293B0A202020';
wwv_flow_imp.g_varchar2_table(700) := '202020202020202020746869732E616E616C797365722E66667453697A65203D20313032343B0A2020202020202020202020207372632E636F6E6E65637428746869732E616E616C79736572293B0A20202020202020207D20636174636820286529207B';
wwv_flow_imp.g_varchar2_table(701) := '20746869732E6163203D206E756C6C3B2072657475726E3B207D0A202020202020202076617220666C203D20747970656F6620746869732E616E616C797365722E676574466C6F617454696D65446F6D61696E44617461203D3D3D202266756E6374696F';
wwv_flow_imp.g_varchar2_table(702) := '6E222C0A20202020202020202020202064617461203D20666C203F206E657720466C6F61743332417272617928746869732E616E616C797365722E66667453697A6529203A206E65772055696E7438417272617928746869732E616E616C797365722E66';
wwv_flow_imp.g_varchar2_table(703) := '667453697A65292C0A20202020202020202020202062617273203D205B5D2C206C617374203D20302C2073686F776E203D20303B0A20202020202020207661722064726177203D2066756E6374696F6E2028747329207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(704) := '696620282173656C662E616E616C7973657229207B2072657475726E3B207D0A20202020202020202020202073656C662E726166203D2072657175657374416E696D6174696F6E4672616D652864726177293B0A2020202020202020202020202F2F2070';
wwv_flow_imp.g_varchar2_table(705) := '65616B206C6576656C20696E2064422C2073686F776E2066726F6D202D35342064422028717569657420726F6F6D2920746F202D3620644220286C6F7564293A20737065656368206D6F76657320746865206261727320636C6561726C790A2020202020';
wwv_flow_imp.g_varchar2_table(706) := '20202020202020766172207065616B203D20302C20692C20763B0A20202020202020202020202069662028666C29207B2073656C662E616E616C797365722E676574466C6F617454696D65446F6D61696E446174612864617461293B20666F7220286920';
wwv_flow_imp.g_varchar2_table(707) := '3D20303B2069203C20646174612E6C656E6774683B20692B2B29207B2076203D204D6174682E61627328646174615B695D293B206966202876203E207065616B29207B207065616B203D20763B207D207D207D0A202020202020202020202020656C7365';
wwv_flow_imp.g_varchar2_table(708) := '207B2073656C662E616E616C797365722E6765744279746554696D65446F6D61696E446174612864617461293B20666F72202869203D20303B2069203C20646174612E6C656E6774683B20692B2B29207B2076203D204D6174682E61627328646174615B';
wwv_flow_imp.g_varchar2_table(709) := '695D202D2031323829202F203132383B206966202876203E207065616B29207B207065616B203D20763B207D207D207D0A202020202020202020202020766172206462203D207065616B203E2030203F203230202A204D6174682E6C6F67287065616B29';
wwv_flow_imp.g_varchar2_table(710) := '202F204D6174682E4C4E3130203A202D3130302C0A202020202020202020202020202020206C766C203D204D6174682E6D617828302C204D6174682E6D696E28312C20286462202B20353429202F20343829293B0A20202020202020202020202073686F';
wwv_flow_imp.g_varchar2_table(711) := '776E203D204D6174682E6D6178286C766C2C2073686F776E202A20302E3835293B0A2020202020202020202020202F2F2073696C656E636520636865636B3A206E6F7468696E672061626F7665202D363020644220666F7220332E35207365636F6E6473';
wwv_flow_imp.g_varchar2_table(712) := '206F66207265636F7264696E670A2020202020202020202020206966202873656C662E7374617465203D3D3D20227265636F7264696E67222026262073656C662E61632026262073656C662E61632E7374617465203D3D3D202272756E6E696E67222920';
wwv_flow_imp.g_varchar2_table(713) := '7B0A20202020202020202020202020202020696620286462203E202D363029207B2073656C662E6865617264203D20747275653B207D20656C736520696620282173656C662E68656172642026262073656C662E7365636F6E64732829203E20332E3529';
wwv_flow_imp.g_varchar2_table(714) := '207B2073656C662E736F756E644C6F737428293B207D0A2020202020202020202020207D0A202020202020202020202020696620282173656C662E68617328226C6576656C4D65746572222929207B2072657475726E3B207D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(715) := '202073656C662E6C6576656C2E66697273744368696C642E7374796C652E7769647468203D204D6174682E726F756E642873686F776E202A2031303029202B202225223B0A2020202020202020202020206966202873656C662E6B696E6420213D3D2022';
wwv_flow_imp.g_varchar2_table(716) := '617564696F2229207B2072657475726E3B207D0A202020202020202020202020766172206376203D2073656C662E63616E7661732C2077203D2063762E636C69656E7457696474682C2068203D2063762E636C69656E744865696768742C20647072203D';
wwv_flow_imp.g_varchar2_table(717) := '2077696E646F772E646576696365506978656C526174696F207C7C20313B0A202020202020202020202020696620282177207C7C20216829207B2072657475726E3B207D0A2020202020202020202020206966202863762E776964746820213D3D204D61';
wwv_flow_imp.g_varchar2_table(718) := '74682E726F756E642877202A2064707229207C7C2063762E68656967687420213D3D204D6174682E726F756E642868202A206470722929207B2063762E7769647468203D204D6174682E726F756E642877202A20647072293B2063762E68656967687420';
wwv_flow_imp.g_varchar2_table(719) := '3D204D6174682E726F756E642868202A20647072293B207D0A202020202020202020202020766172206277203D20332C20676170203D20322C206D6178203D204D6174682E666C6F6F722877202F20286277202B2067617029293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(720) := '20202020696620287473202D206C617374203E2037302026262073656C662E737461746520213D3D20227061757365642229207B0A202020202020202020202020202020206C617374203D2074733B0A2020202020202020202020202020202062617273';
wwv_flow_imp.g_varchar2_table(721) := '2E707573682873656C662E7374617465203D3D3D20227265636F7264696E6722203F2073686F776E203A2073686F776E202A20302E36293B0A202020202020202020202020202020207768696C652028626172732E6C656E677468203E206D617829207B';
wwv_flow_imp.g_varchar2_table(722) := '20626172732E736869667428293B207D0A2020202020202020202020207D0A2020202020202020202020207661722067203D2063762E676574436F6E746578742822326422292C206373203D20676574436F6D70757465645374796C652873656C662E72';
wwv_flow_imp.g_varchar2_table(723) := '6F6F74293B0A202020202020202020202020672E7365745472616E73666F726D286470722C20302C20302C206470722C20302C2030293B0A202020202020202020202020672E636C6561725265637428302C20302C20772C2068293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(724) := '2020202020672E66696C6C5374796C65203D2073656C662E7374617465203D3D3D20227265636F7264696E6722203F2063732E67657450726F706572747956616C756528222D2D6D706C75732D7761766522292E7472696D2829207C7C20222363623131';
wwv_flow_imp.g_varchar2_table(725) := '303022203A2063732E67657450726F706572747956616C756528222D2D6D706C75732D776176652D69646C6522292E7472696D2829207C7C202223393939223B0A202020202020202020202020666F722028766172206A203D20303B206A203C20626172';
wwv_flow_imp.g_varchar2_table(726) := '732E6C656E6774683B206A2B2B29207B0A20202020202020202020202020202020766172206268203D204D6174682E6D617828322C20626172735B6A5D202A202868202D203429292C2078203D2077202D2028626172732E6C656E677468202D206A2920';
wwv_flow_imp.g_varchar2_table(727) := '2A20286277202B20676170293B0A20202020202020202020202020202020672E66696C6C5265637428782C202868202D20626829202F20322C2062772C206268293B0A2020202020202020202020207D0A20202020202020207D3B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(728) := '746869732E726166203D2072657175657374416E696D6174696F6E4672616D652864726177293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6D6574657253746F70203D2066756E6374696F6E202829207B0A202020';
wwv_flow_imp.g_varchar2_table(729) := '202020202069662028746869732E72616629207B2063616E63656C416E696D6174696F6E4672616D6528746869732E726166293B207D0A2020202020202020746869732E726166203D206E756C6C3B0A2020202020202020746869732E616E616C797365';
wwv_flow_imp.g_varchar2_table(730) := '72203D206E756C6C3B0A202020202020202069662028746869732E616329207B20746869732E61632E636C6F736528292E63617463682866756E6374696F6E202829207B202F2A20616C726561647920636C6F736564202A2F207D293B207D0A20202020';
wwv_flow_imp.g_varchar2_table(731) := '20202020746869732E6163203D206E756C6C3B0A2020202020202020746869732E6C6576656C2E66697273744368696C642E7374796C652E7769647468203D202230223B0A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(732) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D206C697665207472616E736372697074696F6E20285765622053706565636820415049290A202020205265636F726465722E7072';
wwv_flow_imp.g_varchar2_table(733) := '6F746F747970652E7374745374617274203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869733B0A2020202020202020746869732E73747454657874203D2022223B0A2020202020202020746869732E7374';
wwv_flow_imp.g_varchar2_table(734) := '74496E746572696D203D2022223B0A2020202020202020746869732E7374744572726F72203D206E756C6C3B0A2020202020202020746869732E73747446696E616C456C2E74657874436F6E74656E74203D2022223B0A2020202020202020746869732E';
wwv_flow_imp.g_varchar2_table(735) := '737474496E746572696D456C2E74657874436F6E74656E74203D2022223B0A20202020202020206966202821746869732E7472616E73637269626573282929207B2072657475726E3B207D0A20202020202020206966202821746869732E535229207B20';
wwv_flow_imp.g_varchar2_table(736) := '746869732E7361792874787428225354545F554E535550504F5254454422292C2022696E666F22293B2072657475726E3B207D0A202020202020202076617220726563203D206E657720746869732E535228293B0A20202020202020207265632E6C616E';
wwv_flow_imp.g_varchar2_table(737) := '67203D20746869732E6C616E673B0A20202020202020207265632E636F6E74696E756F7573203D20747275653B0A20202020202020207265632E696E746572696D526573756C7473203D20747275653B0A20202020202020207265632E6F6E726573756C';
wwv_flow_imp.g_varchar2_table(738) := '74203D2066756E6374696F6E20286529207B0A20202020202020202020202076617220696E746572696D203D2022223B0A202020202020202020202020666F7220287661722069203D20652E726573756C74496E6465783B2069203C20652E726573756C';
wwv_flow_imp.g_varchar2_table(739) := '74732E6C656E6774683B20692B2B29207B0A202020202020202020202020202020207661722074203D20652E726573756C74735B695D5B305D2E7472616E7363726970743B0A2020202020202020202020202020202069662028652E726573756C74735B';
wwv_flow_imp.g_varchar2_table(740) := '695D2E697346696E616C29207B0A202020202020202020202020202020202020202074203D20742E7472696D28293B0A2020202020202020202020202020202020202020696620287429207B2073656C662E73747454657874202B3D202873656C662E73';
wwv_flow_imp.g_varchar2_table(741) := '747454657874203F20222022203A20222229202B20743B207D0A202020202020202020202020202020207D20656C7365207B0A2020202020202020202020202020202020202020696E746572696D202B3D20743B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(742) := '207D0A2020202020202020202020207D0A20202020202020202020202073656C662E737474496E746572696D203D20696E746572696D3B0A20202020202020202020202073656C662E73747446696E616C456C2E74657874436F6E74656E74203D207365';
wwv_flow_imp.g_varchar2_table(743) := '6C662E73747454657874202B202873656C662E7374745465787420262620696E746572696D203F20222022203A202222293B0A20202020202020202020202073656C662E737474496E746572696D456C2E74657874436F6E74656E74203D20696E746572';
wwv_flow_imp.g_varchar2_table(744) := '696D3B0A20202020202020202020202073656C662E73796E6328293B0A20202020202020207D3B0A20202020202020207265632E6F6E6572726F72203D2066756E6374696F6E20286529207B0A20202020202020202020202069662028652E6572726F72';
wwv_flow_imp.g_varchar2_table(745) := '203D3D3D20226E6F2D73706565636822207C7C20652E6572726F72203D3D3D202261626F727465642229207B2072657475726E3B207D0A20202020202020202020202073656C662E7374744572726F72203D20652E6572726F723B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(746) := '2020202073656C662E73747457616E746564203D2066616C73653B0A20202020202020202020202073656C662E7361792874787428225354545F4641494C4544222C20652E6572726F72292C2022696E666F22293B0A20202020202020207D3B0A202020';
wwv_flow_imp.g_varchar2_table(747) := '20202020207265632E6F6E656E64203D2066756E6374696F6E202829207B0A2020202020202020202020202F2F2062726F777365727320656E6420612073657373696F6E20616674657220612073696C656E63653A206361727279206F6E207768696C65';
wwv_flow_imp.g_varchar2_table(748) := '207374696C6C207265636F7264696E670A2020202020202020202020206966202873656C662E73747457616E7465642026262073656C662E7374617465203D3D3D20227265636F7264696E672229207B0A20202020202020202020202020202020747279';
wwv_flow_imp.g_varchar2_table(749) := '207B207265632E737461727428293B207D20636174636820287829207B202F2A20616C72656164792072756E6E696E67202A2F207D0A2020202020202020202020207D20656C7365206966202873656C662E737474446F6E6529207B0A20202020202020';
wwv_flow_imp.g_varchar2_table(750) := '20202020202020202073656C662E737474446F6E6528293B0A2020202020202020202020207D0A20202020202020207D3B0A2020202020202020746869732E737474203D207265633B0A2020202020202020746869732E73747457616E746564203D2074';
wwv_flow_imp.g_varchar2_table(751) := '7275653B0A2020202020202020746869732E737474496E746572696D456C2E74657874436F6E74656E74203D2074787428225452414E5343524942494E4722293B0A2020202020202020747279207B207265632E737461727428293B207D206361746368';
wwv_flow_imp.g_varchar2_table(752) := '20286529207B202F2A207374617274656420616C7265616479202A2F207D0A2020202020202020746869732E73796E6328293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E7374745061757365203D2066756E637469';
wwv_flow_imp.g_varchar2_table(753) := '6F6E20286F6E29207B0A20202020202020206966202821746869732E737474207C7C20746869732E7374744572726F7229207B2072657475726E3B207D0A2020202020202020746869732E73747457616E746564203D20216F6E3B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(754) := '747279207B20696620286F6E29207B20746869732E7374742E73746F7028293B207D20656C7365207B20746869732E7374742E737461727428293B207D207D20636174636820286529207B202F2A20737461746520616C7265616479207269676874202A';
wwv_flow_imp.g_varchar2_table(755) := '2F207D0A202020207D3B0A0A202020202F2F2073746F70206C697374656E696E6720616E642077616974202862726965666C792920666F7220746865206C61737420776F7264730A202020205265636F726465722E70726F746F747970652E7374744669';
wwv_flow_imp.g_varchar2_table(756) := '6E697368203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C20726563203D20746869732E7374743B0A2020202020202020746869732E737474203D206E756C6C3B0A20202020202020206966202821';
wwv_flow_imp.g_varchar2_table(757) := '72656329207B2072657475726E2050726F6D6973652E7265736F6C766528293B207D0A2020202020202020746869732E73747457616E746564203D2066616C73653B0A202020202020202072657475726E206E65772050726F6D6973652866756E637469';
wwv_flow_imp.g_varchar2_table(758) := '6F6E20287265736F6C766529207B0A20202020202020202020202076617220646F6E65203D2066756E6374696F6E202829207B2073656C662E737474446F6E65203D206E756C6C3B207265736F6C766528293B207D3B0A20202020202020202020202073';
wwv_flow_imp.g_varchar2_table(759) := '656C662E737474446F6E65203D20646F6E653B0A20202020202020202020202073657454696D656F757428646F6E652C2031353030293B0A202020202020202020202020747279207B207265632E73746F7028293B207D20636174636820286529207B20';
wwv_flow_imp.g_varchar2_table(760) := '646F6E6528293B207D0A20202020202020207D292E7468656E2866756E6374696F6E202829207B0A2020202020202020202020202F2F206D616B65207375726520697420686173206C657420676F206F6620746865206D6963726F70686F6E652028694F';
wwv_flow_imp.g_varchar2_table(761) := '53206B656570732074686520617564696F20696E207265636F7264696E67206D6F646520756E74696C20697420686173290A2020202020202020202020207265632E6F6E656E64203D207265632E6F6E726573756C74203D207265632E6F6E6572726F72';
wwv_flow_imp.g_varchar2_table(762) := '203D206E756C6C3B0A202020202020202020202020747279207B207265632E61626F727428293B207D20636174636820286529207B202F2A20656E646564202A2F207D0A2020202020202020202020206966202873656C662E737474496E746572696D29';
wwv_flow_imp.g_varchar2_table(763) := '207B2073656C662E73747454657874202B3D202873656C662E73747454657874203F20222022203A20222229202B2073656C662E737474496E746572696D2E7472696D28293B207D0A20202020202020202020202073656C662E737474496E746572696D';
wwv_flow_imp.g_varchar2_table(764) := '203D2022223B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73747441626F7274203D2066756E6374696F6E202829207B0A202020202020202069662028746869732E73747429207B2074';
wwv_flow_imp.g_varchar2_table(765) := '6869732E73747457616E746564203D2066616C73653B20747279207B20746869732E7374742E61626F727428293B207D20636174636820286529207B202F2A2073746F70706564202A2F207D207D0A2020202020202020746869732E737474203D206E75';
wwv_flow_imp.g_varchar2_table(766) := '6C6C3B0A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D207265636F7264696E670A202020205265';
wwv_flow_imp.g_varchar2_table(767) := '636F726465722E70726F746F747970652E7374617274203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869733B0A202020202020202069662028746869732E64697361626C6564207C7C20746869732E6675';
wwv_flow_imp.g_varchar2_table(768) := '6C6C2829207C7C2021746869732E737570706F7274656429207B2072657475726E3B207D0A202020202020202069662028746869732E7374617465203D3D3D202269646C652229207B0A202020202020202020202020746869732E6F70656E28292E7468';
wwv_flow_imp.g_varchar2_table(769) := '656E2866756E6374696F6E202829207B0A202020202020202020202020202020206966202873656C662E63616D657261282929207B2073656C662E73657453746174652822726561647922293B207D20656C7365207B2073656C662E626567696E28293B';
wwv_flow_imp.g_varchar2_table(770) := '207D0A2020202020202020202020207D292E63617463682866756E6374696F6E202829207B202F2A206D6573736167652073686F776E2C206F722063616E63656C6C6564202A2F207D293B0A20202020202020207D20656C73652069662028746869732E';
wwv_flow_imp.g_varchar2_table(771) := '7374617465203D3D3D202272656164792229207B0A20202020202020202020202069662028746869732E6B696E64203D3D3D2022696D6167652229207B20746869732E6361707475726528293B207D20656C7365207B20746869732E626567696E28293B';
wwv_flow_imp.g_varchar2_table(772) := '207D0A20202020202020207D0A202020207D3B0A0A202020202F2F2070686F746F3A207468652063757272656E742063616D657261206672616D652C206174207468652063616D65726127732066756C6C207265736F6C7574696F6E20286E6F74206D69';
wwv_flow_imp.g_varchar2_table(773) := '72726F726564290A202020205265636F726465722E70726F746F747970652E63617074757265203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C2076203D20746869732E766964656F2C2077203D20';
wwv_flow_imp.g_varchar2_table(774) := '762E766964656F57696474682C2068203D20762E766964656F4865696768743B0A202020202020202069662028746869732E737461746520213D3D2022726561647922207C7C202177207C7C20216829207B2072657475726E3B207D0A20202020202020';
wwv_flow_imp.g_varchar2_table(775) := '207661722063203D2063616E7661734F6628772C2068293B0A2020202020202020632E676574436F6E746578742822326422292E64726177496D61676528762C20302C20302C20772C2068293B0A2020202020202020746869732E73746167652E636C61';
wwv_flow_imp.g_varchar2_table(776) := '73734C6973742E616464282269732D666C61736822293B0A202020202020202073657454696D656F75742866756E6374696F6E202829207B2073656C662E73746167652E636C6173734C6973742E72656D6F7665282269732D666C61736822293B207D2C';
wwv_flow_imp.g_varchar2_table(777) := '20323030293B0A2020202020202020746869732E7365745374617465282273746F7070696E6722293B0A2020202020202020746869732E726177426C6F62203D206E756C6C3B0A2020202020202020656E636F646528632C2022696D6167652F6A706567';
wwv_flow_imp.g_varchar2_table(778) := '222C20302E3935292E7468656E2866756E6374696F6E20286229207B0A20202020202020202020202073656C662E72656C6561736528293B0A20202020202020202020202073656C662E75706C6F61644E616D65203D206E756C6C3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(779) := '202020202073656C662E70656E64696E674E616D65203D206E756C6C3B0A20202020202020202020202073656C662E66697265282263617074757265222C207B2077696474683A20772C206865696768743A2068207D293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(780) := '2073656C662E74616B6528622C206E756C6C2C202222293B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E626567696E203D2066756E6374696F6E202829207B0A20202020202020207661';
wwv_flow_imp.g_varchar2_table(781) := '722073656C66203D20746869733B0A202020202020202069662028746869732E6861732822636F756E74646F776E222929207B0A202020202020202020202020766172206E203D20333B0A202020202020202020202020746869732E7365745374617465';
wwv_flow_imp.g_varchar2_table(782) := '2822636F756E74646F776E22293B0A202020202020202020202020746869732E636F756E74646F776E2E74657874436F6E74656E74203D206E3B0A202020202020202020202020746869732E636454696D6572203D20736574496E74657276616C286675';
wwv_flow_imp.g_varchar2_table(783) := '6E6374696F6E202829207B0A202020202020202020202020202020206E2D2D3B0A20202020202020202020202020202020696620286E203E203029207B2073656C662E636F756E74646F776E2E74657874436F6E74656E74203D206E3B2072657475726E';
wwv_flow_imp.g_varchar2_table(784) := '3B207D0A20202020202020202020202020202020636C656172496E74657276616C2873656C662E636454696D6572293B0A2020202020202020202020202020202073656C662E636F756E74646F776E2E74657874436F6E74656E74203D2022223B0A2020';
wwv_flow_imp.g_varchar2_table(785) := '20202020202020202020202020206966202873656C662E7374617465203D3D3D2022636F756E74646F776E2229207B2073656C662E7265636F726428293B207D0A2020202020202020202020207D2C2031303030293B0A20202020202020207D20656C73';
wwv_flow_imp.g_varchar2_table(786) := '65207B0A202020202020202020202020746869732E7265636F726428293B0A20202020202020207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E7265636F7264203D2066756E6374696F6E202829207B0A2020202020';
wwv_flow_imp.g_varchar2_table(787) := '2020207661722073656C66203D20746869732C2071203D20746869732E7175616C69747928292C206F707473203D207B7D2C0A2020202020202020202020206D696D65203D207069636B4D696D6528746869732E6B696E642C20746869732E6366672E66';
wwv_flow_imp.g_varchar2_table(788) := '6F726D6174293B0A202020202020202076617220616B627073203D20746869732E617564696F4B627073286D696D65293B0A2020202020202020696620286D696D6529207B206F7074732E6D696D6554797065203D206D696D653B207D0A202020202020';
wwv_flow_imp.g_varchar2_table(789) := '202069662028746869732E77697468536F756E64282929207B206F7074732E617564696F426974735065725365636F6E64203D20616B627073202A20313030303B207D0A202020202020202069662028746869732E6B696E64203D3D3D2022766964656F';
wwv_flow_imp.g_varchar2_table(790) := '2229207B206F7074732E766964656F426974735065725365636F6E64203D20712E766964656F4B627073202A20313030303B207D0A2020202020202020746869732E6865617264203D2066616C73653B0A2020202020202020746869732E736F756E6457';
wwv_flow_imp.g_varchar2_table(791) := '61726E6564203D2066616C73653B0A2020202020202020747279207B0A202020202020202020202020746869732E726563203D206E6577204D656469615265636F7264657228746869732E73747265616D2C206F707473293B0A20202020202020207D20';
wwv_flow_imp.g_varchar2_table(792) := '636174636820286529207B0A202020202020202020202020747279207B20746869732E726563203D206E6577204D656469615265636F7264657228746869732E73747265616D293B207D2063617463682028653229207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(793) := '20202020746869732E72656C6561736528293B20746869732E7365745374617465282269646C6522293B20746869732E7361792874787428224E4F545F535550504F5254454422292C20226572726F7222293B2072657475726E3B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(794) := '202020207D0A20202020202020207D0A2020202020202020746869732E6368756E6B73203D205B5D3B0A2020202020202020746869732E6279746573203D20303B0A2020202020202020746869732E6C6173744368756E6B203D20303B0A202020202020';
wwv_flow_imp.g_varchar2_table(795) := '2020746869732E6368756E6B4174203D20303B0A20202020202020202F2F20627974657320706572207365636F6E642061736B656420666F72202D20636F76657273206461746120746865207265636F7264657220686173206E6F742068616E64656420';
wwv_flow_imp.g_varchar2_table(796) := '6F7665722079657420284368726F6D652064656C6976657273204D5034206C617465290A2020202020202020746869732E627073203D202828746869732E77697468536F756E642829203F20616B627073203A203029202B2028746869732E6B696E6420';
wwv_flow_imp.g_varchar2_table(797) := '3D3D3D2022766964656F22203F20712E766964656F4B627073203A20302929202A2031303030202F20383B0A2020202020202020746869732E656C6170736564203D20303B0A2020202020202020746869732E73696E6365203D20446174652E6E6F7728';
wwv_flow_imp.g_varchar2_table(798) := '293B0A2020202020202020746869732E7761726E6564203D2066616C73653B0A2020202020202020746869732E73746F70526561736F6E203D206E756C6C3B0A2020202020202020746869732E7265632E6F6E64617461617661696C61626C65203D2066';
wwv_flow_imp.g_varchar2_table(799) := '756E6374696F6E20286529207B0A20202020202020202020202069662028652E6461746120262620652E646174612E73697A6529207B0A2020202020202020202020202020202073656C662E6368756E6B732E7075736828652E64617461293B0A202020';
wwv_flow_imp.g_varchar2_table(800) := '2020202020202020202020202073656C662E6279746573202B3D20652E646174612E73697A653B0A2020202020202020202020202020202073656C662E6C6173744368756E6B203D20652E646174612E73697A653B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(801) := '202073656C662E6368756E6B4174203D2073656C662E7365636F6E647328293B0A2020202020202020202020202020202073656C662E636865636B28293B0A2020202020202020202020207D0A20202020202020207D3B0A202020202020202074686973';
wwv_flow_imp.g_varchar2_table(802) := '2E7265632E6F6E73746F70203D2066756E6374696F6E202829207B2073656C662E66696E697368656428293B207D3B0A2020202020202020746869732E7265632E6F6E6572726F72203D2066756E6374696F6E20286529207B2073656C662E7361792828';
wwv_flow_imp.g_varchar2_table(803) := '652E6572726F7220262620652E6572726F722E6D65737361676529207C7C2074787428224E4F545F535550504F5254454422292C20226572726F7222293B207D3B0A2020202020202020746869732E7265632E73746172742831303030293B0A20202020';
wwv_flow_imp.g_varchar2_table(804) := '20202020746869732E736179282222293B0A2020202020202020746869732E736574537461746528227265636F7264696E6722293B0A2020202020202020746869732E737474537461727428293B0A2020202020202020746869732E7469636B203D2073';
wwv_flow_imp.g_varchar2_table(805) := '6574496E74657276616C2866756E6374696F6E202829207B2073656C662E636865636B28293B207D2C20323530293B0A2020202020202020746869732E636865636B28293B0A2020202020202020746869732E6669726528227374617274222C207B206B';
wwv_flow_imp.g_varchar2_table(806) := '696E643A20746869732E6B696E642C206D696D65547970653A20746869732E7265632E6D696D6554797065207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E7365636F6E6473203D2066756E6374696F6E202829';
wwv_flow_imp.g_varchar2_table(807) := '207B0A202020202020202072657475726E2028746869732E656C6170736564202B2028746869732E7374617465203D3D3D20227265636F7264696E6722203F20446174652E6E6F772829202D20746869732E73696E6365203A20302929202F2031303030';
wwv_flow_imp.g_varchar2_table(808) := '3B0A202020207D3B0A0A202020202F2F2073697A65202F206C656E677468206C696D6974732C207761726E696E672C206D657465720A202020205265636F726465722E70726F746F747970652E636865636B203D2066756E6374696F6E202829207B0A20';
wwv_flow_imp.g_varchar2_table(809) := '2020202020202069662028746869732E737461746520213D3D20227265636F7264696E672220262620746869732E737461746520213D3D20227061757365642229207B2072657475726E3B207D0A20202020202020207661722063203D20746869732E63';
wwv_flow_imp.g_varchar2_table(810) := '66672C20736563203D20746869732E7365636F6E647328292C206C6167203D204D6174682E6D617828302C20736563202D20746869732E6368756E6B4174292C0A20202020202020202020202073697A65203D20746869732E6279746573202B206C6167';
wwv_flow_imp.g_varchar2_table(811) := '202A20746869732E6270732C0A2020202020202020202020202F2F207768696C65207468652073697A65206973206F6E6C7920657374696D6174656420286E6F206461746120666F722061207768696C653A204D5034292C2073746F702061206C697474';
wwv_flow_imp.g_varchar2_table(812) := '6C65206561726C790A202020202020202020202020746172676574203D20632E6D61784279746573202A20286C6167203E20312E35203F20302E3934203A2031292C0A20202020202020202020202073697A65526174696F203D2073697A65202F207461';
wwv_flow_imp.g_varchar2_table(813) := '726765742C0A20202020202020202020202074696D65526174696F203D20632E6D61784475726174696F6E203F20736563202F20632E6D61784475726174696F6E203A20302C0A202020202020202020202020726174696F203D204D6174682E6D696E28';
wwv_flow_imp.g_varchar2_table(814) := '312C204D6174682E6D61782873697A65526174696F2C2074696D65526174696F29292C0A2020202020202020202020207761726E4174203D2028632E7761726E506374207C7C20383029202F203130302C0A20202020202020202020202072617465203D';
wwv_flow_imp.g_varchar2_table(815) := '20736563203E2032203F2073697A65202F20736563203A20302C0A2020202020202020202020206C656674203D2072617465203F2028746172676574202D2073697A6529202F2072617465203A20303B0A202020202020202069662028632E6D61784475';
wwv_flow_imp.g_varchar2_table(816) := '726174696F6E29207B206C656674203D206C656674203F204D6174682E6D696E286C6566742C20632E6D61784475726174696F6E202D2073656329203A20632E6D61784475726174696F6E202D207365633B207D0A0A2020202020202020746869732E74';
wwv_flow_imp.g_varchar2_table(817) := '696D65722E74657874436F6E74656E74203D20666D7454696D6528736563293B0A2020202020202020746869732E6D6574657246696C6C2E7374796C652E7769647468203D2028726174696F202A20313030292E746F4669786564283129202B20222522';
wwv_flow_imp.g_varchar2_table(818) := '3B0A2020202020202020746869732E6D657465724261722E7365744174747269627574652822617269612D76616C75656E6F77222C204D6174682E726F756E6428726174696F202A2031303029293B0A2020202020202020746869732E6D657465722E63';
wwv_flow_imp.g_varchar2_table(819) := '6C6173734C6973742E746F67676C65282269732D7761726E222C20726174696F203E3D207761726E4174293B0A20202020202020202F2F2074696D65206669727374202D207468617420697320776861742070656F706C65207468696E6B20696E3B2074';
wwv_flow_imp.g_varchar2_table(820) := '68652073697A652061667465722069740A2020202020202020746869732E6D65746572546578742E74657874436F6E74656E74203D206C656674203E203020262620736563203E2032203F2074787428224D45544552222C20666D7454696D65286C6566';
wwv_flow_imp.g_varchar2_table(821) := '74292C20666D7442797465732873697A65292C20666D74427974657328632E6D617842797465732929203A2074787428224F46222C20666D7442797465732873697A65292C20666D74427974657328632E6D6178427974657329293B0A0A202020202020';
wwv_flow_imp.g_varchar2_table(822) := '20206966202821746869732E7761726E656420262620726174696F203E3D207761726E4174202626207761726E4174203C203129207B0A202020202020202020202020746869732E7761726E6564203D20747275653B0A20202020202020202020202074';
wwv_flow_imp.g_varchar2_table(823) := '6869732E7361792874696D65526174696F203E2073697A65526174696F203F2074787428225741524E5F54494D45222C20666D7454696D6528736563292C20666D7454696D6528632E6D61784475726174696F6E2929203A2074787428225741524E5F53';
wwv_flow_imp.g_varchar2_table(824) := '495A45222C20666D7442797465732873697A65292C20666D74427974657328632E6D6178427974657329292C20227761726E22293B0A202020202020202020202020696620286E6176696761746F722E7669627261746529207B206E6176696761746F72';
wwv_flow_imp.g_varchar2_table(825) := '2E7669627261746528323030293B207D0A202020202020202020202020746869732E6669726528227761726E696E67222C207B2062797465733A2073697A652C207365636F6E64733A207365632C206D617842797465733A20632E6D617842797465732C';
wwv_flow_imp.g_varchar2_table(826) := '206D61784475726174696F6E3A20632E6D61784475726174696F6E207D293B0A20202020202020207D0A20202020202020202F2F2073746F70207768696C6520746865206E657874206F6E652D7365636F6E642070617274207374696C6C20666974730A';
wwv_flow_imp.g_varchar2_table(827) := '2020202020202020766172206E657874203D204D6174682E6D617828746869732E6C6173744368756E6B2C207261746529202A20312E353B0A202020202020202069662028746869732E7374617465203D3D3D20227265636F7264696E67222026262073';
wwv_flow_imp.g_varchar2_table(828) := '697A65202B206E657874203E3D2074617267657429207B0A202020202020202020202020746869732E73746F70282273697A6522293B0A20202020202020207D20656C73652069662028746869732E7374617465203D3D3D20227265636F7264696E6722';
wwv_flow_imp.g_varchar2_table(829) := '20262620632E6D61784475726174696F6E20262620736563203E3D20632E6D61784475726174696F6E29207B0A202020202020202020202020746869732E73746F7028226475726174696F6E22293B0A20202020202020207D0A202020207D3B0A0A2020';
wwv_flow_imp.g_varchar2_table(830) := '20205265636F726465722E70726F746F747970652E746F67676C655061757365203D2066756E6374696F6E202829207B0A202020202020202069662028746869732E7374617465203D3D3D20227061757365642229207B20746869732E726573756D6528';
wwv_flow_imp.g_varchar2_table(831) := '293B207D20656C7365207B20746869732E706175736528293B207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E7061757365203D2066756E6374696F6E202829207B0A202020202020202069662028746869732E7374';
wwv_flow_imp.g_varchar2_table(832) := '61746520213D3D20227265636F7264696E6722207C7C2021746869732E72656329207B2072657475726E3B207D0A2020202020202020746869732E7265632E706175736528293B0A2020202020202020746869732E656C6170736564202B3D2044617465';
wwv_flow_imp.g_varchar2_table(833) := '2E6E6F772829202D20746869732E73696E63653B0A2020202020202020746869732E73747450617573652874727565293B0A2020202020202020746869732E7365745374617465282270617573656422293B0A2020202020202020746869732E66697265';
wwv_flow_imp.g_varchar2_table(834) := '28227061757365222C207B207365636F6E64733A20746869732E7365636F6E64732829207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E726573756D65203D2066756E6374696F6E202829207B0A202020202020';
wwv_flow_imp.g_varchar2_table(835) := '202069662028746869732E737461746520213D3D202270617573656422207C7C2021746869732E72656329207B2072657475726E3B207D0A2020202020202020746869732E7265632E726573756D6528293B0A2020202020202020746869732E73696E63';
wwv_flow_imp.g_varchar2_table(836) := '65203D20446174652E6E6F7728293B0A2020202020202020746869732E736574537461746528227265636F7264696E6722293B0A2020202020202020746869732E73747450617573652866616C7365293B0A2020202020202020746869732E6669726528';
wwv_flow_imp.g_varchar2_table(837) := '22726573756D65222C207B207365636F6E64733A20746869732E7365636F6E64732829207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73746F70203D2066756E6374696F6E2028726561736F6E29207B0A2020';
wwv_flow_imp.g_varchar2_table(838) := '20202020202069662028746869732E7374617465203D3D3D20226F70656E696E672229207B0A202020202020202020202020746869732E63616E63656C6C6564203D20747275653B0A202020202020202020202020746869732E72656C6561736528293B';
wwv_flow_imp.g_varchar2_table(839) := '0A202020202020202020202020746869732E7365745374617465282269646C6522293B0A20202020202020202020202072657475726E3B0A20202020202020207D0A202020202020202069662028746869732E7374617465203D3D3D2022636F756E7464';
wwv_flow_imp.g_varchar2_table(840) := '6F776E2229207B0A202020202020202020202020636C656172496E74657276616C28746869732E636454696D6572293B0A202020202020202020202020746869732E636F756E74646F776E2E74657874436F6E74656E74203D2022223B0A202020202020';
wwv_flow_imp.g_varchar2_table(841) := '202020202020746869732E72656C6561736528293B0A202020202020202020202020746869732E7365745374617465282269646C6522293B0A20202020202020202020202072657475726E3B0A20202020202020207D0A20202020202020206966202821';
wwv_flow_imp.g_varchar2_table(842) := '746869732E726563207C7C2028746869732E737461746520213D3D20227265636F7264696E672220262620746869732E737461746520213D3D2022706175736564222929207B2072657475726E3B207D0A202020202020202069662028746869732E7374';
wwv_flow_imp.g_varchar2_table(843) := '617465203D3D3D20227265636F7264696E672229207B20746869732E656C6170736564202B3D20446174652E6E6F772829202D20746869732E73696E63653B207D0A2020202020202020746869732E73746F70526561736F6E203D20747970656F662072';
wwv_flow_imp.g_varchar2_table(844) := '6561736F6E203D3D3D2022737472696E6722203F20726561736F6E203A206E756C6C3B0A2020202020202020636C656172496E74657276616C28746869732E7469636B293B0A2020202020202020746869732E7365745374617465282273746F7070696E';
wwv_flow_imp.g_varchar2_table(845) := '6722293B0A2020202020202020747279207B20746869732E7265632E73746F7028293B207D20636174636820286529207B20746869732E66696E697368656428293B207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E';
wwv_flow_imp.g_varchar2_table(846) := '66696E6973686564203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C2063203D20746869732E6366672C206D696D65203D202828746869732E72656320262620746869732E7265632E6D696D655479';
wwv_flow_imp.g_varchar2_table(847) := '706529207C7C2028746869732E6368756E6B735B305D20262620746869732E6368756E6B735B305D2E7479706529207C7C2028746869732E6B696E64202B20222F7765626D2229292E73706C697428223B22295B305D2C0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(848) := '626C6F62203D206E657720426C6F6228746869732E6368756E6B732C207B20747970653A206D696D65207D292C20736563203D20746869732E656C6170736564202F20313030303B0A2020202020202020746869732E72656C6561736528293B0A202020';
wwv_flow_imp.g_varchar2_table(849) := '2020202020746869732E6368756E6B73203D205B5D3B0A2020202020202020746869732E726563203D206E756C6C3B0A202020202020202069662028746869732E73746F70526561736F6E203D3D3D202273697A652229207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(850) := '2020746869732E73617928747874282253544F505045445F53495A45222C20666D74427974657328632E6D6178427974657329292C20227761726E22293B0A202020202020202020202020746869732E6669726528226C696D6974222C207B2072656173';
wwv_flow_imp.g_varchar2_table(851) := '6F6E3A202273697A65222C2062797465733A20626C6F622E73697A652C207365636F6E64733A20736563207D293B0A20202020202020207D20656C73652069662028746869732E73746F70526561736F6E203D3D3D20226475726174696F6E2229207B0A';
wwv_flow_imp.g_varchar2_table(852) := '202020202020202020202020746869732E73617928747874282253544F505045445F54494D45222C20666D7454696D6528632E6D61784475726174696F6E29292C20227761726E22293B0A202020202020202020202020746869732E6669726528226C69';
wwv_flow_imp.g_varchar2_table(853) := '6D6974222C207B20726561736F6E3A20226475726174696F6E222C2062797465733A20626C6F622E73697A652C207365636F6E64733A20736563207D293B0A20202020202020207D20656C73652069662028746869732E73746F70526561736F6E20213D';
wwv_flow_imp.g_varchar2_table(854) := '3D2022646576696365222026262021746869732E7374744572726F7229207B0A202020202020202020202020746869732E736179282222293B0A20202020202020207D0A202020202020202050726F6D6973652E616C6C285B6669784D6564696128626C';
wwv_flow_imp.g_varchar2_table(855) := '6F622C20736563202A2031303030292C20746869732E73747446696E69736828295D292E7468656E2866756E6374696F6E202872657329207B0A202020202020202020202020766172206669786564203D207265735B305D3B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(856) := '2020617564696F53657373696F6E2822706C61796261636B22293B0A2020202020202020202020202F2F20746865207265636F7264696E67206173207468652062726F777365722077726F7465206974202D207573656420696620746869732062726F77';
wwv_flow_imp.g_varchar2_table(857) := '7365722063616E6E6F7420706C6179207468652072657061697265642066696C650A20202020202020202020202073656C662E726177426C6F62203D20666978656420213D3D20626C6F62203F20626C6F62203A206E756C6C3B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(858) := '20202069662028617065782E646562756729207B20617065782E64656275672E696E666F28224D65646961506C7573222C2073656C662E6366672E6974656D2C206D696D652C20227265636F72646564222C20626C6F622E73697A652C20227265706169';
wwv_flow_imp.g_varchar2_table(859) := '726564222C20666978656420213D3D20626C6F62203F2066697865642E73697A65203A20226E6F22293B207D0A20202020202020202020202073656C662E66697265282273746F70222C207B2062797465733A2066697865642E73697A652C207365636F';
wwv_flow_imp.g_varchar2_table(860) := '6E64733A207365632C206D696D65547970653A206D696D65207D293B0A202020202020202020202020696620282166697865642E73697A6529207B2073656C662E7365745374617465282269646C6522293B2072657475726E3B207D0A20202020202020';
wwv_flow_imp.g_varchar2_table(861) := '20202020202F2F206E65766572207468726F772061207265636F7264696E6720617761793A206F6E65206F76657220746865206C696D6974206973206F66666572656420666F7220646F776E6C6F61640A20202020202020202020202073656C662E746F';
wwv_flow_imp.g_varchar2_table(862) := '6F426967203D2066697865642E73697A65203E20632E6D61784279746573202A2028632E616C6C6F77616E6365207C7C2031293B0A2020202020202020202020206966202873656C662E746F6F42696729207B2073656C662E736179287478742822544F';
wwv_flow_imp.g_varchar2_table(863) := '4F5F4C415247455F4B454550222C20666D7442797465732866697865642E73697A65292C20666D74427974657328632E6D6178427974657329292C20226572726F7222293B207D0A20202020202020202020202073656C662E74616B652866697865642C';
wwv_flow_imp.g_varchar2_table(864) := '207365632C2073656C662E7472616E736372696265732829203F2073656C662E73747454657874203A2022222C2073656C662E746F6F426967293B0A20202020202020207D293B0A202020207D3B0A0A202020202F2F20612066696E6973686564207265';
wwv_flow_imp.g_varchar2_table(865) := '636F7264696E67206F7220612063686F73656E2066696C653A20726576696577206974206F72207361766520697420737472616967687420617761790A202020205265636F726465722E70726F746F747970652E74616B65203D2066756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(866) := '28626C6F622C207365632C207472616E7363726970742C206D75737452657669657729207B0A20202020202020207661722073656C66203D20746869733B0A2020202020202020746869732E70656E64696E67426C6F62203D20626C6F623B0A20202020';
wwv_flow_imp.g_varchar2_table(867) := '20202020746869732E70656E64696E67536563203D207365633B0A2020202020202020746869732E6661696C6564203D2066616C73653B0A2020202020202020746869732E726576696577546578742E76616C7565203D20287472616E73637269707420';
wwv_flow_imp.g_varchar2_table(868) := '7C7C202222292E736C69636528302C204D41585F5452414E534352495054293B0A20202020202020206966202828626C6F622E74797065207C7C202222292E696E6465784F662822696D6167652F2229203D3D3D203029207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(869) := '20202F2F20612070686F746F20616C7761797320676F6573207468726F7567682074686520656469746F723A20697420697320726573697A656420616E6420636F6D707265737365642074686572652C206576656E20776974686F757420726576696577';
wwv_flow_imp.g_varchar2_table(870) := '0A202020202020202020202020746869732E6B696E64203D2022696D616765223B0A202020202020202020202020746869732E65644C6F616428626C6F62292E7468656E2866756E6374696F6E202829207B0A2020202020202020202020202020202069';
wwv_flow_imp.g_varchar2_table(871) := '66202873656C662E6861732822707265766965772229207C7C2073656C662E746F6F6C732E6C656E677468207C7C206D75737452657669657729207B2073656C662E73686F7752657669657728293B207D20656C7365207B2073656C662E616363657074';
wwv_flow_imp.g_varchar2_table(872) := '28293B207D0A2020202020202020202020207D292E63617463682866756E6374696F6E20286529207B0A2020202020202020202020202020202073656C662E6564203D206E756C6C3B0A2020202020202020202020202020202073656C662E70656E6469';
wwv_flow_imp.g_varchar2_table(873) := '6E67426C6F62203D206E756C6C3B0A2020202020202020202020202020202073656C662E7365745374617465282269646C6522293B0A2020202020202020202020202020202073656C662E73617928747874282250484F544F5F4641494C4544222C2028';
wwv_flow_imp.g_varchar2_table(874) := '6520262620652E6D65737361676529207C7C202222292C20226572726F7222293B0A2020202020202020202020207D293B0A20202020202020202020202072657475726E3B0A20202020202020207D0A2020202020202020746869732E6564203D206E75';
wwv_flow_imp.g_varchar2_table(875) := '6C6C3B0A202020202020202069662028746869732E6861732822707265766965772229207C7C206D75737452657669657729207B0A202020202020202020202020746869732E73686F7752657669657728293B0A20202020202020207D20656C7365207B';
wwv_flow_imp.g_varchar2_table(876) := '0A202020202020202020202020746869732E61636365707428293B0A20202020202020207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E66696C654E616D65203D2066756E6374696F6E20286D696D652C206B696E64';
wwv_flow_imp.g_varchar2_table(877) := '29207B0A20202020202020207661722064203D206E6577204461746528292C2070203D2066756E6374696F6E20286E29207B2072657475726E20537472696E67286E292E706164537461727428322C20223022293B207D2C0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(878) := '207374616D70203D20642E67657446756C6C596561722829202B207028642E6765744D6F6E74682829202B203129202B207028642E67657444617465282929202B20222D22202B207028642E676574486F757273282929202B207028642E6765744D696E';
wwv_flow_imp.g_varchar2_table(879) := '75746573282929202B207028642E6765745365636F6E64732829293B0A202020202020202072657475726E2028746869732E6366672E66696C654E616D65207C7C2022234954454D232D2354494D455354414D502322290A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(880) := '2E7265706C616365282F234954454D232F672C20746869732E6366672E6974656D2E746F4C6F776572436173652829290A2020202020202020202020202E7265706C616365282F2354494D455354414D50232F672C207374616D70290A20202020202020';
wwv_flow_imp.g_varchar2_table(881) := '20202020202E7265706C616365282F234B494E44232F672C206B696E64290A2020202020202020202020202E7265706C616365282F234E232F672C20746869732E6974656D732E6C656E677468202B2031290A2020202020202020202020202E7265706C';
wwv_flow_imp.g_varchar2_table(882) := '616365282F5B5E5C772E5C2D205D2B2F672C20225F2229202B20222E22202B20657874466F72286D696D65293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73686F77526576696577203D2066756E6374696F6E2028';
wwv_flow_imp.g_varchar2_table(883) := '29207B0A202020202020202069662028746869732E656429207B0A202020202020202020202020746869732E70656E64696E674E616D65203D20746869732E70656E64696E674E616D65207C7C2028746869732E75706C6F61644E616D65203F20746869';
wwv_flow_imp.g_varchar2_table(884) := '732E75706C6F61644E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C202222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C20225F2229203A206E756C6C293B0A202020202020202020202020746869732E61446F776E6C6F6164';
wwv_flow_imp.g_varchar2_table(885) := '2E68726566203D202223223B0A202020202020202020202020746869732E7365745374617465282272657669657722293B0A202020202020202020202020746869732E73617665447261667428293B0A202020202020202020202020746869732E656452';
wwv_flow_imp.g_varchar2_table(886) := '656E64657228293B0A20202020202020202020202028746869732E746F6F426967203F20746869732E61446F776E6C6F6164203A20746869732E62557365292E666F63757328293B0A20202020202020202020202072657475726E3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(887) := '207D0A20202020202020207661722073656C66203D20746869732C20626C6F62203D20746869732E70656E64696E67426C6F622C206B696E64203D20626C6F622E747970652E696E6465784F662822766964656F2229203D3D3D2030203F202276696465';
wwv_flow_imp.g_varchar2_table(888) := '6F22203A2022617564696F222C0A2020202020202020202020206D203D20656C286B696E642C20226D706C75732D6D65646961222C207B20636F6E74726F6C733A20747275652C20706C617973696E6C696E653A206B696E64203D3D3D2022766964656F';
wwv_flow_imp.g_varchar2_table(889) := '22203F2074727565203A206E756C6C2C207072656C6F61643A20226D6574616461746122207D293B0A202020202020202069662028746869732E72657669657755726C29207B2055524C2E7265766F6B654F626A65637455524C28746869732E72657669';
wwv_flow_imp.g_varchar2_table(890) := '657755726C293B207D0A2020202020202020746869732E72657669657755726C203D2055524C2E6372656174654F626A65637455524C28626C6F62293B0A20202020202020206D2E6164644576656E744C697374656E65722822706C6179222C2066756E';
wwv_flow_imp.g_varchar2_table(891) := '6374696F6E202829207B20617564696F53657373696F6E2822706C61796261636B22293B207D293B0A20202020202020206D2E6164644576656E744C697374656E657228226572726F72222C2066756E6374696F6E202829207B2073656C662E706C6179';
wwv_flow_imp.g_varchar2_table(892) := '4572726F72286D2C20626C6F62293B207D293B0A20202020202020206669784475726174696F6E286D293B0A20202020202020206D2E737263203D20746869732E72657669657755726C3B0A2020202020202020746869732E706C617965722E696E6E65';
wwv_flow_imp.g_varchar2_table(893) := '7248544D4C203D2022223B0A2020202020202020746869732E706C617965722E617070656E644368696C64286D293B0A2020202020202020746869732E7265766965774D6574612E74657874436F6E74656E74203D2028746869732E70656E64696E6753';
wwv_flow_imp.g_varchar2_table(894) := '6563203F20666D7454696D6528746869732E70656E64696E6753656329202B202220C2B72022203A20222229202B20666D74427974657328626C6F622E73697A65293B0A2020202020202020746869732E70656E64696E674E616D65203D20746869732E';
wwv_flow_imp.g_varchar2_table(895) := '70656E64696E674E616D65207C7C2028746869732E75706C6F61644E616D65203F20746869732E75706C6F61644E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C202222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C20225F22';
wwv_flow_imp.g_varchar2_table(896) := '29202B20222E22202B20657874466F7228626C6F622E7479706529203A20746869732E66696C654E616D6528626C6F622E747970652C206B696E6429293B0A2020202020202020746869732E61446F776E6C6F61642E68726566203D20746869732E7265';
wwv_flow_imp.g_varchar2_table(897) := '7669657755726C3B0A2020202020202020746869732E61446F776E6C6F61642E7365744174747269627574652822646F776E6C6F6164222C20746869732E70656E64696E674E616D65293B0A2020202020202020746869732E7365745374617465282272';
wwv_flow_imp.g_varchar2_table(898) := '657669657722293B0A2020202020202020746869732E73617665447261667428293B0A202020202020202028746869732E746F6F426967203F20746869732E61446F776E6C6F6164203A20746869732E62557365292E666F63757328293B0A202020207D';
wwv_flow_imp.g_varchar2_table(899) := '3B0A0A202020202F2F207468652072657669657720706C617965722063616E6E6F7420706C6179207468652066696C653A2075736520746865207265636F7264696E67206173207468652062726F777365722077726F74652069742C2069662069742077';
wwv_flow_imp.g_varchar2_table(900) := '61732072657061697265643B0A202020202F2F206F74686572776973652073617920736F2028446F776E6C6F6164207374696C6C20776F726B73290A202020205265636F726465722E70726F746F747970652E706C61794572726F72203D2066756E6374';
wwv_flow_imp.g_varchar2_table(901) := '696F6E20286D2C20626C6F6229207B0A202020202020202076617220636F6465203D206D2E6572726F72203F206D2E6572726F722E636F6465203A20302C206D7367203D20286D2E6572726F72202626206D2E6572726F722E6D65737361676529207C7C';
wwv_flow_imp.g_varchar2_table(902) := '2022223B0A202020202020202069662028617065782E646562756729207B20617065782E64656275672E7761726E28224D65646961506C7573222C20746869732E6366672E6974656D2C20227265766965772063616E6E6F7420706C6179222C20626C6F';
wwv_flow_imp.g_varchar2_table(903) := '622E747970652C20626C6F622E73697A652C2022636F6465222C20636F64652C206D7367293B207D0A202020202020202069662028626C6F6220213D3D20746869732E70656E64696E67426C6F62207C7C20746869732E737461746520213D3D20227265';
wwv_flow_imp.g_varchar2_table(904) := '766965772229207B2072657475726E3B207D0A202020202020202069662028746869732E726177426C6F6220262620746869732E726177426C6F6220213D3D20626C6F6229207B0A202020202020202020202020746869732E70656E64696E67426C6F62';
wwv_flow_imp.g_varchar2_table(905) := '203D20746869732E726177426C6F623B0A202020202020202020202020746869732E726177426C6F62203D206E756C6C3B0A202020202020202020202020746869732E73686F7752657669657728293B0A20202020202020202020202072657475726E3B';
wwv_flow_imp.g_varchar2_table(906) := '0A20202020202020207D0A2020202020202020746869732E736179287478742822504C41595F4641494C4544222C20222822202B20286D7367207C7C2022636F64652022202B20636F646529202B20222922292C20227761726E22293B0A202020207D3B';
wwv_flow_imp.g_varchar2_table(907) := '0A0A202020205265636F726465722E70726F746F747970652E736176654472616674203D2066756E6374696F6E202829207B0A20202020202020206966202821746869732E70656E64696E67426C6F62207C7C20746869732E746F6F42696729207B2072';
wwv_flow_imp.g_varchar2_table(908) := '657475726E3B207D0A20202020202020206472616674732E70757428746869732E64726166744B65792C207B20626C6F623A20746869732E70656E64696E67426C6F622C207261773A20746869732E726177426C6F62207C7C206E756C6C2C2074797065';
wwv_flow_imp.g_varchar2_table(909) := '3A20746869732E70656E64696E67426C6F622E747970652C207365633A20746869732E70656E64696E675365632C206E616D653A20746869732E70656E64696E674E616D652C0A2020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(910) := '202020202020207472616E7363726970743A20746869732E726576696577546578742E76616C75652C2061743A20446174652E6E6F772829207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E64726F7044726166';
wwv_flow_imp.g_varchar2_table(911) := '74203D2066756E6374696F6E202829207B206472616674732E64656C28746869732E64726166744B6579293B207D3B0A0A202020202F2F2061207265636F7264696E6720726576696577656420627574206E657665722075736564202872656C6F61642C';
wwv_flow_imp.g_varchar2_table(912) := '2063726173682C20657870697265642073657373696F6E2920636F6D6573206261636B0A202020205265636F726465722E70726F746F747970652E7265636F766572203D2066756E6374696F6E202829207B0A20202020202020207661722073656C6620';
wwv_flow_imp.g_varchar2_table(913) := '3D20746869732C20736B6970203D206E756C6C3B0A20202020202020202F2F20746865207061676520776173207375626D6974746564207769746820616E20616C6C6F77656420726571756573742028652E672E2043414E43454C293A2074686520756E';
wwv_flow_imp.g_varchar2_table(914) := '66696E6973686564207265636F7264696E67207761732064726F70706564206F6E20707572706F73650A2020202020202020747279207B20736B6970203D2073657373696F6E53746F726167652E6765744974656D28226D706C75732D6E6F6472616674';
wwv_flow_imp.g_varchar2_table(915) := '3A22202B20746869732E64726166744B6579293B2073657373696F6E53746F726167652E72656D6F76654974656D28226D706C75732D6E6F64726166743A22202B20746869732E64726166744B6579293B207D20636174636820286529207B202F2A206E';
wwv_flow_imp.g_varchar2_table(916) := '6F2073746F72616765202A2F207D0A202020202020202069662028736B697029207B20746869732E64726F70447261667428293B2072657475726E3B207D0A20202020202020206472616674732E67657428746869732E64726166744B6579292E746865';
wwv_flow_imp.g_varchar2_table(917) := '6E2866756E6374696F6E20286429207B0A202020202020202020202020696620282164207C7C2021642E626C6F62207C7C2073656C662E737461746520213D3D202269646C6522207C7C2073656C662E66756C6C282929207B2072657475726E3B207D0A';
wwv_flow_imp.g_varchar2_table(918) := '20202020202020202020202069662028446174652E6E6F772829202D20642E6174203E2044524146545F44415953202A20383634653529207B2073656C662E64726F70447261667428293B2072657475726E3B207D0A2020202020202020202020202F2F';
wwv_flow_imp.g_varchar2_table(919) := '20636F7069656420696E746F206D656D6F72793A205361666172692063616E6E6F7420616C7761797320706C617920612066696C652073747261696768742066726F6D20496E646578656444420A20202020202020202020202076617220636F7079203D';
wwv_flow_imp.g_varchar2_table(920) := '2066756E6374696F6E20286229207B2072657475726E2062203F20622E617272617942756666657228292E7468656E2866756E6374696F6E20287829207B2072657475726E206E657720426C6F62285B785D2C207B20747970653A20622E74797065207C';
wwv_flow_imp.g_varchar2_table(921) := '7C20642E74797065207D293B207D29203A2050726F6D6973652E7265736F6C7665286E756C6C293B207D3B0A20202020202020202020202050726F6D6973652E616C6C285B636F707928642E626C6F62292C20636F707928642E726177295D292E746865';
wwv_flow_imp.g_varchar2_table(922) := '6E2866756E6374696F6E202872657329207B0A202020202020202020202020202020206966202873656C662E737461746520213D3D202269646C652229207B2072657475726E3B207D0A2020202020202020202020202020202073656C662E70656E6469';
wwv_flow_imp.g_varchar2_table(923) := '6E674E616D65203D20642E6E616D653B0A2020202020202020202020202020202073656C662E726177426C6F62203D207265735B315D3B0A2020202020202020202020202020202073656C662E74616B65287265735B305D2C20642E7365632C20642E74';
wwv_flow_imp.g_varchar2_table(924) := '72616E7363726970742C2074727565293B0A2020202020202020202020202020202073656C662E7361792874787428225245434F564552454422292C2022696E666F22293B0A2020202020202020202020207D292E63617463682866756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(925) := '2829207B2073656C662E64726F70447261667428293B207D293B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E636C656172526576696577203D2066756E6374696F6E202829207B0A2020';
wwv_flow_imp.g_varchar2_table(926) := '202020202020766172206D203D20746869732E706C617965722E717565727953656C6563746F722822617564696F2C766964656F22293B0A2020202020202020696620286D29207B206D2E706175736528293B207D0A2020202020202020746869732E70';
wwv_flow_imp.g_varchar2_table(927) := '6C617965722E696E6E657248544D4C203D2022223B0A202020202020202069662028746869732E72657669657755726C29207B2055524C2E7265766F6B654F626A65637455524C28746869732E72657669657755726C293B207D0A202020202020202069';
wwv_flow_imp.g_varchar2_table(928) := '662028746869732E646C55726C29207B2055524C2E7265766F6B654F626A65637455524C28746869732E646C55726C293B207D0A2020202020202020746869732E72657669657755726C203D20746869732E646C55726C203D206E756C6C3B0A20202020';
wwv_flow_imp.g_varchar2_table(929) := '20202020746869732E6564203D206E756C6C3B0A2020202020202020746869732E65644361636865203D20746869732E656442757379203D206E756C6C3B0A202020207D3B0A0A202020202F2F206E616D65206F6620612070686F746F3A207468652063';
wwv_flow_imp.g_varchar2_table(930) := '686F73656E2066696C652773206E616D65206F72207468652046696C65204E616D65207061747465726E2C207769746820746865206F757470757420666F726D6174277320657874656E73696F6E0A202020205265636F726465722E70726F746F747970';
wwv_flow_imp.g_varchar2_table(931) := '652E70686F746F4E616D65203D2066756E6374696F6E20286D696D6529207B0A202020202020202072657475726E2028746869732E70656E64696E674E616D65203F20746869732E70656E64696E674E616D652E7265706C616365282F5C2E5B5E2E5D2A';
wwv_flow_imp.g_varchar2_table(932) := '242F2C20222229202B20222E22202B20657874466F72286D696D6529203A20746869732E66696C654E616D65286D696D652C2022696D6167652229293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E64697363617264';
wwv_flow_imp.g_varchar2_table(933) := '203D2066756E6374696F6E2028616761696E29207B0A20202020202020207661722073656C66203D20746869732C0A202020202020202020202020676F203D2066756E6374696F6E202829207B0A2020202020202020202020202020202073656C662E63';
wwv_flow_imp.g_varchar2_table(934) := '6C65617252657669657728293B0A2020202020202020202020202020202073656C662E70656E64696E67426C6F62203D206E756C6C3B0A2020202020202020202020202020202073656C662E726177426C6F62203D206E756C6C3B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(935) := '202020202020202073656C662E70656E64696E674E616D65203D206E756C6C3B0A2020202020202020202020202020202073656C662E746F6F426967203D2066616C73653B0A2020202020202020202020202020202073656C662E6661696C6564203D20';
wwv_flow_imp.g_varchar2_table(936) := '66616C73653B0A2020202020202020202020202020202073656C662E726576696577546578742E76616C7565203D2022223B0A2020202020202020202020202020202073656C662E64726F70447261667428293B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(937) := '2073656C662E736179282222293B0A2020202020202020202020202020202073656C662E7365745374617465282269646C6522293B0A2020202020202020202020202020202073656C662E6669726528226469736361726422293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(938) := '202020202020202069662028616761696E29207B2073656C662E737461727428293B207D0A2020202020202020202020207D3B0A202020202020202069662028746869732E737461746520213D3D20227265766965772229207B2072657475726E3B207D';
wwv_flow_imp.g_varchar2_table(939) := '0A20202020202020206966202821616761696E20262620746869732E6861732822636F6E6669726D44656C657465222929207B0A202020202020202020202020617065782E6D6573736167652E636F6E6669726D287478742822434F4E4649524D5F4449';
wwv_flow_imp.g_varchar2_table(940) := '534341524422292C2066756E6374696F6E20286F6B29207B20696620286F6B29207B20676F28293B207D207D293B0A20202020202020207D20656C7365207B0A202020202020202020202020676F28293B0A20202020202020207D0A202020207D3B0A0A';
wwv_flow_imp.g_varchar2_table(941) := '202020205265636F726465722E70726F746F747970652E75736546696C65203D2066756E6374696F6E202866696C6529207B0A20202020202020207661722073656C66203D20746869732C2063203D20746869732E6366672C2074797065203D20286669';
wwv_flow_imp.g_varchar2_table(942) := '6C652E74797065207C7C202222292E746F4C6F7765724361736528292C206B696E64203D20747970652E73706C697428222F22295B305D3B0A202020202020202069662028746869732E6B696E64732E696E6465784F66286B696E6429203C203029207B';
wwv_flow_imp.g_varchar2_table(943) := '20746869732E73617928747874282246494C455F57524F4E475F5459504522292C20226572726F7222293B2072657475726E3B207D0A20202020202020202F2F2070686F746F7320617265206D61646520736D616C6C657220696E207468652065646974';
wwv_flow_imp.g_varchar2_table(944) := '6F722C20736F2061206C617267652070686F746F2069732066696E653B207265636F7264696E6773206D757374206669742061732074686579206172650A2020202020202020696620286B696E6420213D3D2022696D616765222026262066696C652E73';
wwv_flow_imp.g_varchar2_table(945) := '697A65203E20632E6D6178427974657329207B20746869732E73617928747874282246494C455F544F4F5F4C41524745222C20666D7442797465732866696C652E73697A65292C20666D74427974657328632E6D6178427974657329292C20226572726F';
wwv_flow_imp.g_varchar2_table(946) := '7222293B2072657475726E3B207D0A2020202020202020746869732E736179282222293B0A2020202020202020746869732E6B696E64203D206B696E643B0A2020202020202020746869732E726177426C6F62203D206E756C6C3B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(947) := '696620286B696E64203D3D3D2022696D6167652229207B0A202020202020202020202020746869732E75706C6F61644E616D65203D2066696C652E6E616D653B0A202020202020202020202020746869732E70656E64696E674E616D65203D206E756C6C';
wwv_flow_imp.g_varchar2_table(948) := '3B0A202020202020202020202020746869732E74616B652866696C652C206E756C6C2C202222293B0A20202020202020202020202072657475726E3B0A20202020202020207D0A20202020202020206D656469614475726174696F6E2866696C65292E74';
wwv_flow_imp.g_varchar2_table(949) := '68656E2866756E6374696F6E202873656329207B0A20202020202020202020202073656C662E75706C6F61644E616D65203D2066696C652E6E616D653B0A20202020202020202020202073656C662E70656E64696E674E616D65203D206E756C6C3B0A20';
wwv_flow_imp.g_varchar2_table(950) := '202020202020202020202073656C662E74616B652866696C652C207365632C202222293B0A20202020202020207D293B0A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D';
wwv_flow_imp.g_varchar2_table(951) := '2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2070686F746F20656469746F720A2020202076617220524154494F53203D207B2022313A31223A20312C2022343A33223A2034202F20332C2022333A34223A2033202F20342C2022';
wwv_flow_imp.g_varchar2_table(952) := '31363A39223A203136202F20392C2022393A3136223A2039202F203136207D2C0A2020202020202020434F4C4F555253203D205B2223653533393335222C202223666464383335222C202223666666666666222C202223323132313231225D3B0A0A2020';
wwv_flow_imp.g_varchar2_table(953) := '20205265636F726465722E70726F746F747970652E6275696C64456469746F72203D2066756E6374696F6E2028746829207B0A20202020202020207661722073656C66203D20746869732C2063203D20746869732E6366672C2074203D20746869732E74';
wwv_flow_imp.g_varchar2_table(954) := '6F6F6C732C20686173203D2066756E6374696F6E20287829207B2072657475726E20742E696E6465784F66287829203E3D20303B207D2C0A2020202020202020202020207462203D2066756E6374696F6E2028636C732C2069636F6E2C206C6162656C29';
wwv_flow_imp.g_varchar2_table(955) := '207B2072657475726E2063746C28226D706C75732D62746E2D2D67686F73742022202B20636C732C2069636F6E2C206C6162656C2C20747275652C207468293B207D2C0A2020202020202020202020206669786564203D20524154494F535B632E63726F';
wwv_flow_imp.g_varchar2_table(956) := '70526174696F5D3B0A2020202020202020746869732E656443616E766173203D20656C282263616E766173222C20226D706C75732D65642D63616E76617322293B0A2020202020202020746869732E656443726F70203D20656C2822646976222C20226D';
wwv_flow_imp.g_varchar2_table(957) := '706C75732D65642D63726F70222C207B20746162696E6465783A202230222C20726F6C653A202267726F7570222C2022617269612D6C6162656C223A20747874282243524F502229207D2C0A2020202020202020202020205B226E77222C20226E222C20';
wwv_flow_imp.g_varchar2_table(958) := '226E65222C202265222C20227365222C202273222C20227377222C202277225D2E6D61702866756E6374696F6E20286829207B2072657475726E20656C28227370616E222C20226D706C75732D65642D68206D706C75732D65642D682D2D22202B20682C';
wwv_flow_imp.g_varchar2_table(959) := '207B2022646174612D68223A2068207D293B207D29293B0A2020202020202020746869732E656457726170203D20656C2822646976222C20226D706C75732D65642D77726170222C206E756C6C2C205B746869732E656443616E7661732C20746869732E';
wwv_flow_imp.g_varchar2_table(960) := '656443726F705D293B0A0A2020202020202020746869732E62526F744C203D20746228226D706C75732D652D726F746C222C202266612D726F746174652D6C656674222C207478742822524F544154455F4C4546542229293B0A20202020202020207468';
wwv_flow_imp.g_varchar2_table(961) := '69732E62526F7452203D20746228226D706C75732D652D726F7472222C202266612D726F746174652D7269676874222C207478742822524F544154455F52494748542229293B0A2020202020202020746869732E62466C6970203D20746228226D706C75';
wwv_flow_imp.g_varchar2_table(962) := '732D652D666C6970222C202266612D6172726F77732D68222C207478742822464C49502229293B0A2020202020202020746869732E6241646A757374203D20746228226D706C75732D652D61646A757374222C202266612D736C6964657273222C207478';
wwv_flow_imp.g_varchar2_table(963) := '74282241444A5553542229293B0A2020202020202020746869732E6247726179203D20746228226D706C75732D652D67726179222C202266612D61646A757374222C207478742822475241595343414C452229293B0A2020202020202020746869732E62';
wwv_flow_imp.g_varchar2_table(964) := '44726177203D20746228226D706C75732D652D64726177222C202266612D70656E63696C222C207478742822445241572229293B0A2020202020202020746869732E62556E646F203D20746228226D706C75732D652D756E646F222C202266612D657261';
wwv_flow_imp.g_varchar2_table(965) := '736572222C207478742822554E444F2229293B0A2020202020202020746869732E625265736574203D2063746C28226D706C75732D62746E2D2D67686F7374206D706C75732D652D7265736574222C202266612D72656672657368222C20747874282252';
wwv_flow_imp.g_varchar2_table(966) := '4553455422292C2066616C73652C207468293B0A2020202020202020746869732E6564526174696F203D20656C282273656C656374222C20226D706C75732D65642D73656C656374206D706C75732D652D726174696F222C207B2022617269612D6C6162';
wwv_flow_imp.g_varchar2_table(967) := '656C223A20747874282243524F5022292C207469746C653A20747874282243524F502229207D2C0A2020202020202020202020205B5B2246524545222C20747874282243524F505F4652454522295D2C205B22313A31222C2022313A31225D2C205B2234';
wwv_flow_imp.g_varchar2_table(968) := '3A33222C2022343A33225D2C205B22333A34222C2022333A34225D2C205B2231363A39222C202231363A39225D2C205B22393A3136222C2022393A3136225D2C205B22414C4C222C20747874282243524F505F414C4C22295D5D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(969) := '202020202020202E6D61702866756E6374696F6E20286F29207B2072657475726E20656C28226F7074696F6E222C206E756C6C2C207B2076616C75653A206F5B305D2C20746578743A206F5B315D207D293B207D29293B0A202020202020202076617220';
wwv_flow_imp.g_varchar2_table(970) := '6D6178203D20632E696D6167654D617853696465207C7C20313932303B0A2020202020202020746869732E656453697A65203D20656C282273656C656374222C20226D706C75732D65642D73656C656374206D706C75732D652D73697A65222C207B2022';
wwv_flow_imp.g_varchar2_table(971) := '617269612D6C6162656C223A20747874282253495A4522292C207469746C653A20747874282253495A452229207D2C0A2020202020202020202020205B6D61785D2E636F6E636174285B313630302C20313238302C20313032342C203830302C20363430';
wwv_flow_imp.g_varchar2_table(972) := '5D2E66696C7465722866756E6374696F6E20287329207B2072657475726E2073203C206D61783B207D29290A202020202020202020202020202020202E6D61702866756E6374696F6E2028732C206929207B2072657475726E20656C28226F7074696F6E';
wwv_flow_imp.g_varchar2_table(973) := '222C206E756C6C2C207B2076616C75653A20732C20746578743A2069203F20747874282253495A455F5058222C207329203A20747874282253495A455F46554C4C222C207329207D293B207D29293B0A2020202020202020746869732E6564436F6C6F75';
wwv_flow_imp.g_varchar2_table(974) := '7273203D20656C28227370616E222C20226D706C75732D65642D636F6C6F757273222C207B20726F6C653A202267726F7570222C2022617269612D6C6162656C223A207478742822445241572229207D2C20434F4C4F5552532E6D61702866756E637469';
wwv_flow_imp.g_varchar2_table(975) := '6F6E2028636F6C29207B0A2020202020202020202020207661722062203D20656C2822627574746F6E222C20226D706C75732D65642D636F6C6F7572222C207B20747970653A2022627574746F6E222C2022617269612D6C6162656C223A20636F6C2C20';
wwv_flow_imp.g_varchar2_table(976) := '7469746C653A20636F6C2C2022617269612D70726573736564223A20537472696E6728636F6C203D3D3D20434F4C4F5552535B305D29207D293B0A202020202020202020202020622E7374796C652E6261636B67726F756E64203D20636F6C3B0A202020';
wwv_flow_imp.g_varchar2_table(977) := '202020202020202020622E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B0A2020202020202020202020202020202073656C662E65642E636F6C6F7572203D20636F6C3B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(978) := '202020202041727261792E70726F746F747970652E666F72456163682E63616C6C2873656C662E6564436F6C6F7572732E6368696C6472656E2C2066756E6374696F6E20287829207B20782E7365744174747269627574652822617269612D7072657373';
wwv_flow_imp.g_varchar2_table(979) := '6564222C20537472696E672878203D3D3D206229293B207D293B0A2020202020202020202020207D293B0A20202020202020202020202072657475726E20623B0A20202020202020207D29293B0A2020202020202020746869732E6564546F6F6C73203D';
wwv_flow_imp.g_varchar2_table(980) := '20656C2822646976222C20226D706C75732D65642D746F6F6C73222C207B20726F6C653A2022746F6F6C626172222C2022617269612D6C6162656C223A20747874282241444A5553542229207D2C205B0A20202020202020202020202068617328226372';
wwv_flow_imp.g_varchar2_table(981) := '6F70222920262620216669786564203F20746869732E6564526174696F203A206E756C6C2C0A2020202020202020202020206861732822726F746174652229203F20746869732E62526F744C203A206E756C6C2C206861732822726F746174652229203F';
wwv_flow_imp.g_varchar2_table(982) := '20746869732E62526F7452203A206E756C6C2C0A2020202020202020202020206861732822666C69702229203F20746869732E62466C6970203A206E756C6C2C0A202020202020202020202020686173282261646A7573742229203F20746869732E6241';
wwv_flow_imp.g_varchar2_table(983) := '646A757374203A206E756C6C2C20686173282261646A7573742229203F20746869732E6247726179203A206E756C6C2C0A2020202020202020202020206861732822647261772229203F20746869732E6244726177203A206E756C6C2C20686173282264';
wwv_flow_imp.g_varchar2_table(984) := '7261772229203F20746869732E6564436F6C6F757273203A206E756C6C2C206861732822647261772229203F20746869732E62556E646F203A206E756C6C2C0A2020202020202020202020206861732822726573697A652229203F20746869732E656453';
wwv_flow_imp.g_varchar2_table(985) := '697A65203A206E756C6C2C0A202020202020202020202020742E6C656E677468203F20746869732E625265736574203A206E756C6C0A20202020202020205D293B0A202020202020202076617220736C69646572203D2066756E6374696F6E20286B6579';
wwv_flow_imp.g_varchar2_table(986) := '2C206C6162656C2C206D696E2C206D617829207B0A2020202020202020202020207661722069203D20656C2822696E707574222C20226D706C75732D65642D72616E6765206D706C75732D652D22202B206B65792C207B20747970653A202272616E6765';
wwv_flow_imp.g_varchar2_table(987) := '222C206D696E3A206D696E2C206D61783A206D61782C2076616C75653A203130302C2022617269612D6C6162656C223A206C6162656C207D293B0A202020202020202020202020692E6164644576656E744C697374656E65722822696E707574222C2066';
wwv_flow_imp.g_varchar2_table(988) := '756E6374696F6E202829207B2073656C662E65642E61646A5B6B65795D203D202B692E76616C75653B2073656C662E65644368616E67656428293B207D293B0A20202020202020202020202072657475726E207B20696E7075743A20692C20626F783A20';
wwv_flow_imp.g_varchar2_table(989) := '656C28226C6162656C222C20226D706C75732D65642D736C69646572222C206E756C6C2C205B656C28227370616E222C206E756C6C2C207B20746578743A206C6162656C207D292C20695D29207D3B0A20202020202020207D3B0A202020202020202074';
wwv_flow_imp.g_varchar2_table(990) := '6869732E7342203D20736C69646572282262222C2074787428224252494748544E45535322292C2034302C20313630293B0A2020202020202020746869732E7343203D20736C69646572282263222C207478742822434F4E545241535422292C2034302C';
wwv_flow_imp.g_varchar2_table(991) := '20313630293B0A2020202020202020746869732E7353203D20736C69646572282273222C20747874282253415455524154494F4E22292C20302C20323030293B0A2020202020202020746869732E656441646A757374203D20656C2822646976222C2022';
wwv_flow_imp.g_varchar2_table(992) := '6D706C75732D65642D61646A757374222C207B2068696464656E3A2074727565207D2C205B746869732E73422E626F782C20746869732E73432E626F782C20746869732E73532E626F785D293B0A2020202020202020746869732E65644D657461203D20';
wwv_flow_imp.g_varchar2_table(993) := '656C28227370616E222C20226D706C75732D65642D6D657461222C207B2022617269612D6C697665223A2022706F6C69746522207D293B0A2020202020202020746869732E70686F746F426F78203D20656C2822646976222C20226D706C75732D656422';
wwv_flow_imp.g_varchar2_table(994) := '2C207B2068696464656E3A2074727565207D2C205B656C2822646976222C20226D706C75732D65642D7374616765222C206E756C6C2C205B746869732E6564577261705D292C20746869732E6564546F6F6C732C20746869732E656441646A7573742C20';
wwv_flow_imp.g_varchar2_table(995) := '746869732E65644D6574615D293B0A202020202020202073686F7728746869732E656443726F702C20686173282263726F702229207C7C2021216669786564293B0A0A2020202020202020746869732E62526F744C2E6164644576656E744C697374656E';
wwv_flow_imp.g_varchar2_table(996) := '65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E6564526F74617465282D3930293B207D293B0A2020202020202020746869732E62526F74522E6164644576656E744C697374656E65722822636C69636B222C2066756E6374';
wwv_flow_imp.g_varchar2_table(997) := '696F6E202829207B2073656C662E6564526F74617465283930293B207D293B0A2020202020202020746869732E62466C69702E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E6564466C';
wwv_flow_imp.g_varchar2_table(998) := '697028293B207D293B0A2020202020202020746869732E6241646A7573742E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B0A202020202020202020202020766172206F6E203D2073656C662E656441';
wwv_flow_imp.g_varchar2_table(999) := '646A7573742E68696464656E3B0A20202020202020202020202073686F772873656C662E656441646A7573742C206F6E293B0A20202020202020202020202073656C662E6241646A7573742E7365744174747269627574652822617269612D7072657373';
wwv_flow_imp.g_varchar2_table(1000) := '6564222C20537472696E67286F6E29293B0A20202020202020207D293B0A2020202020202020746869732E62477261792E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E65642E677261';
wwv_flow_imp.g_varchar2_table(1001) := '79203D202173656C662E65642E677261793B2073656C662E62477261792E7365744174747269627574652822617269612D70726573736564222C20537472696E672873656C662E65642E6772617929293B2073656C662E65644368616E67656428293B20';
wwv_flow_imp.g_varchar2_table(1002) := '7D293B0A2020202020202020746869732E62447261772E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E656453657444726177696E67282173656C662E65642E64726177696E67293B20';
wwv_flow_imp.g_varchar2_table(1003) := '7D293B0A2020202020202020746869732E62556E646F2E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E65642E7374726F6B65732E706F7028293B2073656C662E65644368616E676564';
wwv_flow_imp.g_varchar2_table(1004) := '28293B207D293B0A2020202020202020746869732E6252657365742E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E6564526573657428293B207D293B0A202020202020202074686973';
wwv_flow_imp.g_varchar2_table(1005) := '2E6564526174696F2E6164644576656E744C697374656E657228226368616E6765222C2066756E6374696F6E202829207B2073656C662E6564536574526174696F2873656C662E6564526174696F2E76616C7565293B207D293B0A202020202020202074';
wwv_flow_imp.g_varchar2_table(1006) := '6869732E656453697A652E6164644576656E744C697374656E657228226368616E6765222C2066756E6374696F6E202829207B2073656C662E65642E73696465203D202B73656C662E656453697A652E76616C75653B2073656C662E65644368616E6765';
wwv_flow_imp.g_varchar2_table(1007) := '642874727565293B207D293B0A2020202020202020746869732E656443726F702E6164644576656E744C697374656E65722822706F696E746572646F776E222C2066756E6374696F6E20286529207B2073656C662E6564506F696E74657228652C20652E';
wwv_flow_imp.g_varchar2_table(1008) := '7461726765742E6765744174747269627574652822646174612D682229207C7C20226D6F766522293B207D293B0A2020202020202020746869732E656443616E7661732E6164644576656E744C697374656E65722822706F696E746572646F776E222C20';
wwv_flow_imp.g_varchar2_table(1009) := '66756E6374696F6E20286529207B206966202873656C662E65642026262073656C662E65642E64726177696E6729207B2073656C662E65644472617753746172742865293B207D207D293B0A20202020202020202F2F207468652063726F7020626F7820';
wwv_flow_imp.g_varchar2_table(1010) := '6279206B6579626F6172643A206172726F7773206D6F76652069742C205368696674202B206172726F777320726573697A652069740A2020202020202020746869732E656443726F702E6164644576656E744C697374656E657228226B6579646F776E22';
wwv_flow_imp.g_varchar2_table(1011) := '2C2066756E6374696F6E20286529207B0A2020202020202020202020207661722064203D207B204172726F774C6566743A205B2D312C20305D2C204172726F7752696768743A205B312C20305D2C204172726F7755703A205B302C202D315D2C20417272';
wwv_flow_imp.g_varchar2_table(1012) := '6F77446F776E3A205B302C20315D207D5B652E6B65795D3B0A202020202020202020202020696620282164207C7C202173656C662E656429207B2072657475726E3B207D0A202020202020202020202020652E70726576656E7444656661756C7428293B';
wwv_flow_imp.g_varchar2_table(1013) := '0A202020202020202020202020766172207374617274203D20242E657874656E64287B7D2C2073656C662E65642E63726F70293B0A20202020202020202020202073656C662E65644472616728652E73686966744B6579203F2028645B305D203F202265';
wwv_flow_imp.g_varchar2_table(1014) := '22203A2022732229203A20226D6F7665222C2073746172742C20645B305D202A20302E30322C20645B315D202A20302E3032293B0A20202020202020202020202073656C662E6564506C61636543726F7028293B0A20202020202020202020202073656C';
wwv_flow_imp.g_varchar2_table(1015) := '662E65644368616E6765642874727565293B0A20202020202020207D293B0A202020202020202077696E646F772E6164644576656E744C697374656E65722822726573697A65222C2066756E6374696F6E202829207B206966202873656C662E65642026';
wwv_flow_imp.g_varchar2_table(1016) := '262073656C662E7374617465203D3D3D20227265766965772229207B2073656C662E656452656E64657228293B207D207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E65645457203D2066756E6374696F6E2028';
wwv_flow_imp.g_varchar2_table(1017) := '29207B2072657475726E20746869732E65642E726F74202520313830203F20746869732E65642E7372632E686569676874203A20746869732E65642E7372632E77696474683B207D3B0A202020205265636F726465722E70726F746F747970652E656454';
wwv_flow_imp.g_varchar2_table(1018) := '48203D2066756E6374696F6E202829207B2072657475726E20746869732E65642E726F74202520313830203F20746869732E65642E7372632E7769647468203A20746869732E65642E7372632E6865696768743B207D3B0A0A202020205265636F726465';
wwv_flow_imp.g_varchar2_table(1019) := '722E70726F746F747970652E65644C6F6164203D2066756E6374696F6E2028626C6F6229207B0A20202020202020207661722073656C66203D20746869733B0A202020202020202072657475726E206C6F616450686F746F28626C6F62292E7468656E28';
wwv_flow_imp.g_varchar2_table(1020) := '66756E6374696F6E202873726329207B0A20202020202020202020202073656C662E6564203D207B207372633A207372632C20726F743A20302C20666C69703A2066616C73652C2063726F703A207B20783A20302C20793A20302C20773A20312C20683A';
wwv_flow_imp.g_varchar2_table(1021) := '2031207D2C20726174696F3A20302C2061646A3A207B20623A203130302C20633A203130302C20733A20313030207D2C20677261793A2066616C73652C0A2020202020202020202020202020202020202020202020207374726F6B65733A205B5D2C2063';
wwv_flow_imp.g_varchar2_table(1022) := '6F6C6F75723A20434F4C4F5552535B305D2C2064726177696E673A2066616C73652C20736964653A2073656C662E6366672E696D6167654D617853696465207C7C2031393230207D3B0A20202020202020202020202073656C662E656456657273696F6E';
wwv_flow_imp.g_varchar2_table(1023) := '203D20303B0A20202020202020202020202073656C662E65644361636865203D2073656C662E656442757379203D206E756C6C3B0A20202020202020202020202073656C662E6564457374696D617465203D206E756C6C3B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(1024) := '2073656C662E6564436F6E74726F6C73526573657428293B0A20202020202020202020202069662028524154494F535B73656C662E6366672E63726F70526174696F5D29207B2073656C662E6564536574526174696F2873656C662E6366672E63726F70';
wwv_flow_imp.g_varchar2_table(1025) := '526174696F2C2074727565293B207D0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6564436F6E74726F6C735265736574203D2066756E6374696F6E202829207B0A202020202020202076';
wwv_flow_imp.g_varchar2_table(1026) := '61722073656C66203D20746869733B0A20202020202020205B746869732E73422C20746869732E73432C20746869732E73535D2E666F72456163682866756E6374696F6E20287329207B20732E696E7075742E76616C7565203D203130303B207D293B0A';
wwv_flow_imp.g_varchar2_table(1027) := '2020202020202020746869732E6564526174696F2E76616C7565203D202246524545223B0A2020202020202020746869732E656453697A652E73656C6563746564496E646578203D20303B0A202020202020202073686F7728746869732E656441646A75';
wwv_flow_imp.g_varchar2_table(1028) := '73742C2066616C7365293B0A20202020202020205B746869732E6241646A7573742C20746869732E62477261792C20746869732E62447261775D2E666F72456163682866756E6374696F6E20286229207B20622E73657441747472696275746528226172';
wwv_flow_imp.g_varchar2_table(1029) := '69612D70726573736564222C202266616C736522293B207D293B0A202020202020202041727261792E70726F746F747970652E666F72456163682E63616C6C28746869732E6564436F6C6F7572732E6368696C6472656E2C2066756E6374696F6E202878';
wwv_flow_imp.g_varchar2_table(1030) := '2C206929207B20782E7365744174747269627574652822617269612D70726573736564222C20537472696E6728216929293B207D293B0A202020202020202073686F7728746869732E6564436F6C6F7572732C2066616C7365293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(1031) := '73686F7728746869732E62556E646F2C2066616C7365293B0A2020202020202020746869732E70686F746F426F782E636C6173734C6973742E72656D6F7665282269732D64726177696E6722293B0A20202020202020206966202873656C662E65644372';
wwv_flow_imp.g_varchar2_table(1032) := '6F7029207B2073656C662E656443726F702E7374796C652E706F696E7465724576656E7473203D2022223B207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E65645265736574203D2066756E6374696F6E202829207B';
wwv_flow_imp.g_varchar2_table(1033) := '0A2020202020202020766172206564203D20746869732E65643B0A202020202020202065642E726F74203D20303B2065642E666C6970203D2066616C73653B2065642E63726F70203D207B20783A20302C20793A20302C20773A20312C20683A2031207D';
wwv_flow_imp.g_varchar2_table(1034) := '3B2065642E726174696F203D20303B0A202020202020202065642E61646A203D207B20623A203130302C20633A203130302C20733A20313030207D3B2065642E67726179203D2066616C73653B2065642E7374726F6B6573203D205B5D3B2065642E6472';
wwv_flow_imp.g_varchar2_table(1035) := '6177696E67203D2066616C73653B2065642E73696465203D20746869732E6366672E696D6167654D617853696465207C7C20313932303B0A2020202020202020746869732E6564436F6E74726F6C73526573657428293B0A202020202020202069662028';
wwv_flow_imp.g_varchar2_table(1036) := '524154494F535B746869732E6366672E63726F70526174696F5D29207B20746869732E6564536574526174696F28746869732E6366672E63726F70526174696F2C2074727565293B207D0A2020202020202020746869732E65644368616E67656428293B';
wwv_flow_imp.g_varchar2_table(1037) := '0A202020207D3B0A0A202020202F2F2074686520707265766965773A207468652077686F6C6520287475726E65642C2061646A7573746564292070686F746F3B207468652063726F702069732074686520626F78206F6E20746F70206F662069740A2020';
wwv_flow_imp.g_varchar2_table(1038) := '20205265636F726465722E70726F746F747970652E656452656E646572203D2066756E6374696F6E202829207B0A20202020202020206966202821746869732E656429207B2072657475726E3B207D0A202020202020202076617220647072203D207769';
wwv_flow_imp.g_varchar2_table(1039) := '6E646F772E646576696365506978656C526174696F207C7C20312C0A20202020202020202020202073696465203D204D6174682E6D696E28323034382C204D6174682E6D6178283634302C204D6174682E726F756E642828746869732E726F6F742E636C';
wwv_flow_imp.g_varchar2_table(1040) := '69656E745769647468207C7C2038303029202A206470722929292C0A20202020202020202020202070203D2072656E64657250686F746F28746869732E65642C20736964652C2066616C7365292C206376203D20746869732E656443616E7661733B0A20';
wwv_flow_imp.g_varchar2_table(1041) := '2020202020202063762E7769647468203D20702E77696474683B0A202020202020202063762E686569676874203D20702E6865696768743B0A202020202020202063762E676574436F6E746578742822326422292E64726177496D61676528702C20302C';
wwv_flow_imp.g_varchar2_table(1042) := '2030293B0A2020202020202020746869732E6564506C61636543726F7028293B0A2020202020202020746869732E65644D65746155706461746528293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6564506C616365';
wwv_flow_imp.g_varchar2_table(1043) := '43726F70203D2066756E6374696F6E202829207B0A20202020202020207661722063203D20746869732E65642E63726F702C2073203D20746869732E656443726F702E7374796C653B0A2020202020202020732E6C656674203D20632E78202A20313030';
wwv_flow_imp.g_varchar2_table(1044) := '202B202225223B0A2020202020202020732E746F70203D20632E79202A20313030202B202225223B0A2020202020202020732E7769647468203D20632E77202A20313030202B202225223B0A2020202020202020732E686569676874203D20632E68202A';
wwv_flow_imp.g_varchar2_table(1045) := '20313030202B202225223B0A202020207D3B0A0A202020202F2F2063726F704F6E6C793A20746865207072657669657720646F6573206E6F74206368616E6765202863726F7020626F782C206F75747075742073697A65290A202020205265636F726465';
wwv_flow_imp.g_varchar2_table(1046) := '722E70726F746F747970652E65644368616E676564203D2066756E6374696F6E202863726F704F6E6C7929207B0A20202020202020207661722073656C66203D20746869733B0A2020202020202020746869732E656456657273696F6E2B2B3B0A202020';
wwv_flow_imp.g_varchar2_table(1047) := '2020202020746869732E6564457374696D617465203D206E756C6C3B0A2020202020202020696620282163726F704F6E6C7929207B0A2020202020202020202020206966202821746869732E656452616629207B20746869732E6564526166203D207265';
wwv_flow_imp.g_varchar2_table(1048) := '7175657374416E696D6174696F6E4672616D652866756E6374696F6E202829207B2073656C662E6564526166203D206E756C6C3B2073656C662E656452656E64657228293B207D293B207D0A20202020202020207D20656C7365207B0A20202020202020';
wwv_flow_imp.g_varchar2_table(1049) := '2020202020746869732E65644D65746155706461746528293B0A20202020202020207D0A20202020202020202F2F207468652066696C652073697A652C206F6E63652074686520757365722073746F7073206368616E67696E67207468696E67730A2020';
wwv_flow_imp.g_varchar2_table(1050) := '202020202020636C65617254696D656F757428746869732E656454696D6572293B0A2020202020202020746869732E656454696D6572203D2073657454696D656F75742866756E6374696F6E202829207B0A202020202020202020202020766172207620';
wwv_flow_imp.g_varchar2_table(1051) := '3D2073656C662E656456657273696F6E3B0A202020202020202020202020696620282173656C662E656429207B2072657475726E3B207D0A20202020202020202020202073656C662E65644578706F727428292E7468656E2866756E6374696F6E202872';
wwv_flow_imp.g_varchar2_table(1052) := '29207B206966202873656C662E65642026262076203D3D3D2073656C662E656456657273696F6E29207B2073656C662E6564457374696D617465203D20722E626C6F622E73697A653B2073656C662E65644D65746155706461746528293B207D207D293B';
wwv_flow_imp.g_varchar2_table(1053) := '0A20202020202020207D2C20373030293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E65644D657461557064617465203D2066756E6374696F6E202829207B0A2020202020202020766172206564203D20746869732E';
wwv_flow_imp.g_varchar2_table(1054) := '65642C2063203D2065642E63726F702C206377203D20632E77202A20746869732E6564545728292C206368203D20632E68202A20746869732E6564544828292C2073203D204D6174682E6D696E28312C2065642E73696465202F204D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(1055) := '63772C20636829293B0A2020202020202020746869732E65644D6574612E74657874436F6E74656E74203D20747874282250484F544F5F4D455441222C204D6174682E726F756E64286377202A2073292C204D6174682E726F756E64286368202A207329';
wwv_flow_imp.g_varchar2_table(1056) := '29202B2028746869732E6564457374696D617465203F202220C2B72022202B20747874282250484F544F5F53495A45222C20666D74427974657328746869732E6564457374696D6174652929203A202222293B0A202020207D3B0A0A202020205265636F';
wwv_flow_imp.g_varchar2_table(1057) := '726465722E70726F746F747970652E65644578706F7274203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C2076203D20746869732E656456657273696F6E2C2063203D20746869732E6366672C0A20';
wwv_flow_imp.g_varchar2_table(1058) := '202020202020202020202074797065203D207B20504E473A2022696D6167652F706E67222C20574542503A2022696D6167652F7765627022207D5B632E696D616765466F726D61745D207C7C2022696D6167652F6A706567223B0A202020202020202069';
wwv_flow_imp.g_varchar2_table(1059) := '662028746869732E6564436163686520262620746869732E656443616368652E76203D3D3D207629207B2072657475726E2050726F6D6973652E7265736F6C766528746869732E656443616368652E72293B207D0A202020202020202069662028746869';
wwv_flow_imp.g_varchar2_table(1060) := '732E65644275737920262620746869732E6564427573792E76203D3D3D207629207B2072657475726E20746869732E6564427573792E703B207D0A20202020202020207661722070203D20656E636F6465546F46697428746869732E65642C2074686973';
wwv_flow_imp.g_varchar2_table(1061) := '2E65642E736964652C20747970652C204D6174682E6D696E28312C204D6174682E6D617828302E332C2028632E696D6167655175616C697479207C7C20383529202F2031303029292C20632E6D61784279746573290A2020202020202020202020202E74';
wwv_flow_imp.g_varchar2_table(1062) := '68656E2866756E6374696F6E20287229207B2073656C662E65644361636865203D207B20763A20762C20723A2072207D3B2072657475726E20723B207D293B0A2020202020202020746869732E656442757379203D207B20763A20762C20703A2070207D';
wwv_flow_imp.g_varchar2_table(1063) := '3B0A202020202020202072657475726E20703B0A202020207D3B0A0A202020202F2F207475726E20627920393020646567726565733B207468652063726F70207475726E732077697468207468652070686F746F2028612063726F702073686170652069';
wwv_flow_imp.g_varchar2_table(1064) := '732066697474656420616761696E290A202020205265636F726465722E70726F746F747970652E6564526F74617465203D2066756E6374696F6E202864656729207B0A2020202020202020766172206564203D20746869732E65642C2063203D2065642E';
wwv_flow_imp.g_varchar2_table(1065) := '63726F703B0A202020202020202065642E726F74203D202865642E726F74202B20646567202B20333630292025203336303B0A202020202020202065642E63726F70203D20646567203E2030203F207B20783A2031202D2028632E79202B20632E68292C';
wwv_flow_imp.g_varchar2_table(1066) := '20793A20632E782C20773A20632E682C20683A20632E77207D203A207B20783A20632E792C20793A2031202D2028632E78202B20632E77292C20773A20632E682C20683A20632E77207D3B0A20202020202020206966202865642E726174696F29207B20';
wwv_flow_imp.g_varchar2_table(1067) := '746869732E65644669742865642E726174696F293B207D0A2020202020202020746869732E65644368616E67656428293B0A202020207D3B0A0A202020202F2F206D6972726F7220776861742069732073686F776E3A20647261776E206173207475726E';
wwv_flow_imp.g_varchar2_table(1068) := '28666C697028736F7572636529292C20736F206120666C6970206F6620746865207475726E65642070686F746F20697320666C6970202B20746865206F70706F73697465207475726E0A202020205265636F726465722E70726F746F747970652E656446';
wwv_flow_imp.g_varchar2_table(1069) := '6C6970203D2066756E6374696F6E202829207B0A2020202020202020766172206564203D20746869732E65643B0A202020202020202065642E666C6970203D202165642E666C69703B0A202020202020202065642E726F74203D2028333630202D206564';
wwv_flow_imp.g_varchar2_table(1070) := '2E726F74292025203336303B0A202020202020202065642E63726F70203D207B20783A2031202D2065642E63726F702E78202D2065642E63726F702E772C20793A2065642E63726F702E792C20773A2065642E63726F702E772C20683A2065642E63726F';
wwv_flow_imp.g_varchar2_table(1071) := '702E68207D3B0A2020202020202020746869732E65644368616E67656428293B0A202020207D3B0A0A202020202F2F206C6172676573742063656E747265642063726F70206F662074686520676976656E20736861706520287769647468202F20686569';
wwv_flow_imp.g_varchar2_table(1072) := '67687420696E20706978656C73290A202020205265636F726465722E70726F746F747970652E6564466974203D2066756E6374696F6E2028726174696F29207B0A2020202020202020766172206E203D20726174696F202A20746869732E656454482829';
wwv_flow_imp.g_varchar2_table(1073) := '202F20746869732E6564545728292C2077203D206E203E3D2031203F2031203A206E2C2068203D206E203E3D2031203F2031202F206E203A20313B0A2020202020202020746869732E65642E63726F70203D207B20783A202831202D207729202F20322C';
wwv_flow_imp.g_varchar2_table(1074) := '20793A202831202D206829202F20322C20773A20772C20683A2068207D3B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6564536574526174696F203D2066756E6374696F6E2028762C20717569657429207B0A202020';
wwv_flow_imp.g_varchar2_table(1075) := '2020202020766172206564203D20746869732E65643B0A20202020202020206966202876203D3D3D2022414C4C2229207B0A20202020202020202020202065642E726174696F203D20303B0A20202020202020202020202065642E63726F70203D207B20';
wwv_flow_imp.g_varchar2_table(1076) := '783A20302C20793A20302C20773A20312C20683A2031207D3B0A202020202020202020202020746869732E6564526174696F2E76616C7565203D202246524545223B0A20202020202020207D20656C7365207B0A20202020202020202020202065642E72';
wwv_flow_imp.g_varchar2_table(1077) := '6174696F203D20524154494F535B765D207C7C20303B0A2020202020202020202020206966202865642E726174696F29207B20746869732E65644669742865642E726174696F293B207D0A20202020202020207D0A202020202020202069662028217175';
wwv_flow_imp.g_varchar2_table(1078) := '69657429207B20746869732E6564506C61636543726F7028293B20746869732E65644368616E6765642874727565293B207D0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E656453657444726177696E67203D2066756E';
wwv_flow_imp.g_varchar2_table(1079) := '6374696F6E20286F6E29207B0A2020202020202020746869732E65642E64726177696E67203D206F6E3B0A2020202020202020746869732E62447261772E7365744174747269627574652822617269612D70726573736564222C20537472696E67286F6E';
wwv_flow_imp.g_varchar2_table(1080) := '29293B0A2020202020202020746869732E70686F746F426F782E636C6173734C6973742E746F67676C65282269732D64726177696E67222C206F6E293B0A2020202020202020746869732E656443726F702E7374796C652E706F696E7465724576656E74';
wwv_flow_imp.g_varchar2_table(1081) := '73203D206F6E203F20226E6F6E6522203A2022223B0A202020202020202073686F7728746869732E6564436F6C6F7572732C206F6E293B0A202020202020202073686F7728746869732E62556E646F2C206F6E293B0A202020207D3B0A0A202020202F2F';
wwv_flow_imp.g_varchar2_table(1082) := '2064726167207468652063726F7020626F7820286D6F646520226D6F76652229206F72206F6E65206F66206974732068616E646C657320286E2C206E652C2065202E2E2E293B206475202F20647620617265206672616374696F6E73206F662074686520';
wwv_flow_imp.g_varchar2_table(1083) := '70686F746F0A202020205265636F726465722E70726F746F747970652E656444726167203D2066756E6374696F6E20286D6F64652C2073746172742C2064752C20647629207B0A2020202020202020766172206564203D20746869732E65642C204D494E';
wwv_flow_imp.g_varchar2_table(1084) := '203D20302E30352C2072203D2065642E726174696F203F2065642E726174696F202A20746869732E656454482829202F20746869732E656454572829203A20302C0A2020202020202020202020207830203D2073746172742E782C207930203D20737461';
wwv_flow_imp.g_varchar2_table(1085) := '72742E792C207831203D2073746172742E78202B2073746172742E772C207931203D2073746172742E79202B2073746172742E683B0A2020202020202020696620286D6F6465203D3D3D20226D6F76652229207B0A20202020202020202020202065642E';
wwv_flow_imp.g_varchar2_table(1086) := '63726F70203D207B20783A204D6174682E6D696E2831202D2073746172742E772C204D6174682E6D617828302C207830202B20647529292C20793A204D6174682E6D696E2831202D2073746172742E682C204D6174682E6D617828302C207930202B2064';
wwv_flow_imp.g_varchar2_table(1087) := '7629292C20773A2073746172742E772C20683A2073746172742E68207D3B0A20202020202020202020202072657475726E3B0A20202020202020207D0A2020202020202020696620286D6F64652E696E6465784F662822772229203E3D203029207B2078';
wwv_flow_imp.g_varchar2_table(1088) := '30203D204D6174682E6D696E287831202D204D494E2C204D6174682E6D617828302C207830202B20647529293B207D0A2020202020202020696620286D6F64652E696E6465784F662822652229203E3D203029207B207831203D204D6174682E6D617828';
wwv_flow_imp.g_varchar2_table(1089) := '7830202B204D494E2C204D6174682E6D696E28312C207831202B20647529293B207D0A2020202020202020696620286D6F64652E696E6465784F6628226E2229203E3D203029207B207930203D204D6174682E6D696E287931202D204D494E2C204D6174';
wwv_flow_imp.g_varchar2_table(1090) := '682E6D617828302C207930202B20647629293B207D0A2020202020202020696620286D6F64652E696E6465784F662822732229203E3D203029207B207931203D204D6174682E6D6178287930202B204D494E2C204D6174682E6D696E28312C207931202B';
wwv_flow_imp.g_varchar2_table(1091) := '20647629293B207D0A20202020202020207661722077203D207831202D2078302C2068203D207931202D2079303B0A2020202020202020696620287229207B0A2020202020202020202020202F2F206B656570207468652073686170653A207468652064';
wwv_flow_imp.g_varchar2_table(1092) := '726167676564207369646520646563696465733B20746865206F70706F73697465207369646520286F72207468652063656E747265292073746179730A202020202020202020202020696620286D6F6465203D3D3D20226E22207C7C206D6F6465203D3D';
wwv_flow_imp.g_varchar2_table(1093) := '3D2022732229207B2077203D2068202A20723B207D20656C7365207B2068203D2077202F20723B207D0A2020202020202020202020206966202877203E203129207B2077203D20313B2068203D2077202F20723B207D0A20202020202020202020202069';
wwv_flow_imp.g_varchar2_table(1094) := '66202868203E203129207B2068203D20313B2077203D2068202A20723B207D0A2020202020202020202020207830203D206D6F64652E696E6465784F662822772229203E3D2030203F207831202D2077203A206D6F64652E696E6465784F662822652229';
wwv_flow_imp.g_varchar2_table(1095) := '203E3D2030203F207830203A2073746172742E78202B2073746172742E77202F2032202D2077202F20323B0A2020202020202020202020207930203D206D6F64652E696E6465784F6628226E2229203E3D2030203F207931202D2068203A206D6F64652E';
wwv_flow_imp.g_varchar2_table(1096) := '696E6465784F662822732229203E3D2030203F207930203A2073746172742E79202B2073746172742E68202F2032202D2068202F20323B0A2020202020202020202020207830203D204D6174682E6D696E284D6174682E6D617828302C207830292C2031';
wwv_flow_imp.g_varchar2_table(1097) := '202D2077293B0A2020202020202020202020207930203D204D6174682E6D696E284D6174682E6D617828302C207930292C2031202D2068293B0A20202020202020207D0A202020202020202065642E63726F70203D207B20783A2078302C20793A207930';
wwv_flow_imp.g_varchar2_table(1098) := '2C20773A20772C20683A2068207D3B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6564506F696E746572203D2066756E6374696F6E2028652C206D6F646529207B0A20202020202020206966202821746869732E6564';
wwv_flow_imp.g_varchar2_table(1099) := '207C7C20652E627574746F6E203E203029207B2072657475726E3B207D0A20202020202020207661722073656C66203D20746869732C20626F78203D20746869732E6564577261702E676574426F756E64696E67436C69656E745265637428292C207374';
wwv_flow_imp.g_varchar2_table(1100) := '617274203D20242E657874656E64287B7D2C20746869732E65642E63726F70292C2078203D20652E636C69656E74582C2079203D20652E636C69656E74592C2074203D20652E7461726765743B0A2020202020202020652E70726576656E744465666175';
wwv_flow_imp.g_varchar2_table(1101) := '6C7428293B0A2020202020202020747279207B20742E736574506F696E7465724361707475726528652E706F696E7465724964293B207D2063617463682028783229207B202F2A206F6C642062726F77736572202A2F207D0A2020202020202020766172';
wwv_flow_imp.g_varchar2_table(1102) := '206D6F7665203D2066756E6374696F6E2028657629207B2073656C662E656444726167286D6F64652C2073746172742C202865762E636C69656E7458202D207829202F20626F782E77696474682C202865762E636C69656E7459202D207929202F20626F';
wwv_flow_imp.g_varchar2_table(1103) := '782E686569676874293B2073656C662E6564506C61636543726F7028293B207D2C0A2020202020202020202020207570203D2066756E6374696F6E202829207B0A20202020202020202020202020202020742E72656D6F76654576656E744C697374656E';
wwv_flow_imp.g_varchar2_table(1104) := '65722822706F696E7465726D6F7665222C206D6F7665293B0A20202020202020202020202020202020742E72656D6F76654576656E744C697374656E65722822706F696E7465727570222C207570293B0A20202020202020202020202020202020742E72';
wwv_flow_imp.g_varchar2_table(1105) := '656D6F76654576656E744C697374656E65722822706F696E74657263616E63656C222C207570293B0A2020202020202020202020202020202073656C662E65644368616E6765642874727565293B0A2020202020202020202020207D3B0A202020202020';
wwv_flow_imp.g_varchar2_table(1106) := '2020742E6164644576656E744C697374656E65722822706F696E7465726D6F7665222C206D6F7665293B0A2020202020202020742E6164644576656E744C697374656E65722822706F696E7465727570222C207570293B0A2020202020202020742E6164';
wwv_flow_imp.g_varchar2_table(1107) := '644576656E744C697374656E65722822706F696E74657263616E63656C222C207570293B0A202020207D3B0A0A202020202F2F206120706F696E74206F662074686520707265766965772028302E2E31206F6620746865207475726E65642070686F746F';
wwv_flow_imp.g_varchar2_table(1108) := '2920696E20736F7572636520636F6F7264696E617465732028302E2E31290A202020205265636F726465722E70726F746F747970652E6564546F536F75726365203D2066756E6374696F6E2028752C207629207B0A202020202020202076617220656420';
wwv_flow_imp.g_varchar2_table(1109) := '3D20746869732E65642C207377203D2065642E7372632E77696474682C207368203D2065642E7372632E6865696768742C2058203D202875202D20302E3529202A20746869732E6564545728292C2059203D202876202D20302E3529202A20746869732E';
wwv_flow_imp.g_varchar2_table(1110) := '6564544828292C0A20202020202020202020202074203D2065642E726F74202A204D6174682E5049202F203138302C206373203D204D6174682E726F756E64284D6174682E636F73287429292C20736E203D204D6174682E726F756E64284D6174682E73';
wwv_flow_imp.g_varchar2_table(1111) := '696E287429292C0A20202020202020202020202061203D2058202A206373202B2059202A20736E2C2062203D202D58202A20736E202B2059202A2063733B0A20202020202020206966202865642E666C697029207B2061203D202D613B207D0A20202020';
wwv_flow_imp.g_varchar2_table(1112) := '2020202072657475726E205B2861202B207377202F203229202F2073772C202862202B207368202F203229202F2073685D3B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6564447261775374617274203D2066756E63';
wwv_flow_imp.g_varchar2_table(1113) := '74696F6E20286529207B0A20202020202020207661722073656C66203D20746869732C206564203D20746869732E65642C206376203D20746869732E656443616E7661732C2072656374203D2063762E676574426F756E64696E67436C69656E74526563';
wwv_flow_imp.g_varchar2_table(1114) := '7428292C2067203D2063762E676574436F6E746578742822326422292C0A2020202020202020202020207374203D207B20636F6C6F75723A2065642E636F6C6F75722C20773A20302E3030362C207074733A205B5D207D2C206C617374203D206E756C6C';
wwv_flow_imp.g_varchar2_table(1115) := '3B0A2020202020202020652E70726576656E7444656661756C7428293B0A2020202020202020747279207B2063762E736574506F696E7465724361707475726528652E706F696E7465724964293B207D20636174636820287829207B202F2A206F6C6420';
wwv_flow_imp.g_varchar2_table(1116) := '62726F77736572202A2F207D0A202020202020202076617220616464203D2066756E6374696F6E2028657629207B0A202020202020202020202020202020207661722075203D204D6174682E6D696E28312C204D6174682E6D617828302C202865762E63';
wwv_flow_imp.g_varchar2_table(1117) := '6C69656E7458202D20726563742E6C65667429202F20726563742E776964746829292C2076203D204D6174682E6D696E28312C204D6174682E6D617828302C202865762E636C69656E7459202D20726563742E746F7029202F20726563742E6865696768';
wwv_flow_imp.g_varchar2_table(1118) := '7429292C0A20202020202020202020202020202020202020207078203D2075202A2063762E77696474682C207079203D2076202A2063762E6865696768743B0A2020202020202020202020202020202073742E7074732E707573682873656C662E656454';
wwv_flow_imp.g_varchar2_table(1119) := '6F536F7572636528752C207629293B0A20202020202020202020202020202020672E7374726F6B655374796C65203D2073742E636F6C6F75723B0A20202020202020202020202020202020672E6C696E655769647468203D204D6174682E6D617828312C';
wwv_flow_imp.g_varchar2_table(1120) := '2073742E77202A204D6174682E6D61782863762E77696474682C2063762E68656967687429293B0A20202020202020202020202020202020672E6C696E65436170203D20672E6C696E654A6F696E203D2022726F756E64223B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(1121) := '202020202020672E626567696E5061746828293B0A20202020202020202020202020202020672E6D6F7665546F286C617374203F206C6173745B305D203A2070782C206C617374203F206C6173745B315D203A207079293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(1122) := '2020202020672E6C696E65546F287078202B20286C617374203F2030203A20302E31292C207079293B0A20202020202020202020202020202020672E7374726F6B6528293B0A202020202020202020202020202020206C617374203D205B70782C207079';
wwv_flow_imp.g_varchar2_table(1123) := '5D3B0A2020202020202020202020207D2C0A2020202020202020202020207570203D2066756E6374696F6E202829207B0A2020202020202020202020202020202063762E72656D6F76654576656E744C697374656E65722822706F696E7465726D6F7665';
wwv_flow_imp.g_varchar2_table(1124) := '222C20616464293B0A2020202020202020202020202020202063762E72656D6F76654576656E744C697374656E65722822706F696E7465727570222C207570293B0A2020202020202020202020202020202063762E72656D6F76654576656E744C697374';
wwv_flow_imp.g_varchar2_table(1125) := '656E65722822706F696E74657263616E63656C222C207570293B0A202020202020202020202020202020206966202873742E7074732E6C656E67746829207B2065642E7374726F6B65732E70757368287374293B207D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1126) := '20202073656C662E65644368616E67656428293B0A2020202020202020202020207D3B0A20202020202020206164642865293B0A202020202020202063762E6164644576656E744C697374656E65722822706F696E7465726D6F7665222C20616464293B';
wwv_flow_imp.g_varchar2_table(1127) := '0A202020202020202063762E6164644576656E744C697374656E65722822706F696E7465727570222C207570293B0A202020202020202063762E6164644576656E744C697374656E65722822706F696E74657263616E63656C222C207570293B0A202020';
wwv_flow_imp.g_varchar2_table(1128) := '207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2075706C6F616420746F2074686520636F6C6C656374696F';
wwv_flow_imp.g_varchar2_table(1129) := '6E0A202020205265636F726465722E70726F746F747970652E6A6F696E6564203D2066756E6374696F6E202829207B0A202020202020202072657475726E20746869732E6974656D732E66696C7465722866756E6374696F6E20287229207B2072657475';
wwv_flow_imp.g_varchar2_table(1130) := '726E20722E7365713B207D292E6D61702866756E6374696F6E20287229207B2072657475726E20722E7472616E7363726970743B207D292E66696C74657228426F6F6C65616E292E6A6F696E28225C6E5C6E22293B0A202020207D3B0A0A202020205265';
wwv_flow_imp.g_varchar2_table(1131) := '636F726465722E70726F746F747970652E616363657074203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C20626C6F62203D20746869732E70656E64696E67426C6F623B0A20202020202020206966';
wwv_flow_imp.g_varchar2_table(1132) := '202821626C6F62207C7C20746869732E746F6F426967207C7C20746869732E6564576F726B696E6729207B2072657475726E3B207D0A20202020202020206966202821746869732E656429207B20746869732E73656E6428626C6F622C206E756C6C293B';
wwv_flow_imp.g_varchar2_table(1133) := '2072657475726E3B207D0A20202020202020202F2F20612070686F746F3A207468652065646974656420706963747572652C20726573697A656420616E6420636F6D7072657373656420756E74696C206974206669747320746865204D6178696D756D20';
wwv_flow_imp.g_varchar2_table(1134) := '46696C652053697A650A2020202020202020746869732E6564576F726B696E67203D20747275653B0A2020202020202020746869732E73796E6328293B0A2020202020202020746869732E736179287478742822505245504152494E4722292C2022696E';
wwv_flow_imp.g_varchar2_table(1135) := '666F22293B0A2020202020202020746869732E65644578706F727428292E7468656E2866756E6374696F6E202872657329207B0A20202020202020202020202073656C662E6564576F726B696E67203D2066616C73653B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1136) := '69662028217265732E6669747329207B0A2020202020202020202020202020202073656C662E73617928747874282250484F544F5F544F4F5F4C41524745222C20666D7442797465732873656C662E6366672E6D6178427974657329292C20226572726F';
wwv_flow_imp.g_varchar2_table(1137) := '7222293B0A202020202020202020202020202020206966202873656C662E7374617465203D3D3D20227265766965772229207B2073656C662E73796E6328293B207D20656C7365207B2073656C662E73686F7752657669657728293B207D0A2020202020';
wwv_flow_imp.g_varchar2_table(1138) := '202020202020202020202072657475726E3B0A2020202020202020202020207D0A20202020202020202020202073656C662E73656E64287265732E626C6F622C207B206E616D653A2073656C662E70686F746F4E616D65287265732E626C6F622E747970';
wwv_flow_imp.g_varchar2_table(1139) := '65292C2077696474683A207265732E77696474682C206865696768743A207265732E686569676874207D293B0A20202020202020207D292E63617463682866756E6374696F6E20286529207B0A20202020202020202020202073656C662E6564576F726B';
wwv_flow_imp.g_varchar2_table(1140) := '696E67203D2066616C73653B0A20202020202020202020202073656C662E73796E6328293B0A20202020202020202020202073656C662E73617928747874282250484F544F5F4641494C4544222C20286520262620652E6D65737361676529207C7C2022';
wwv_flow_imp.g_varchar2_table(1141) := '22292C20226572726F7222293B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73656E64203D2066756E6374696F6E2028626C6F622C2070686F746F29207B0A2020202020202020766172';
wwv_flow_imp.g_varchar2_table(1142) := '2073656C66203D20746869732C0A2020202020202020202020206B696E64203D20626C6F622E747970652E73706C697428222F22295B305D203D3D3D2022766964656F22203F2022766964656F22203A20626C6F622E747970652E73706C697428222F22';
wwv_flow_imp.g_varchar2_table(1143) := '295B305D203D3D3D2022696D61676522203F2022696D61676522203A2022617564696F222C0A2020202020202020202020206D696D65203D2028626C6F622E74797065207C7C206B696E64202B20222F7765626D22292E73706C697428223B22295B305D';
wwv_flow_imp.g_varchar2_table(1144) := '2C0A2020202020202020202020206E616D65203D2070686F746F203F2070686F746F2E6E616D65203A20746869732E70656E64696E674E616D65207C7C2028746869732E75706C6F61644E616D65203F20746869732E75706C6F61644E616D652E726570';
wwv_flow_imp.g_varchar2_table(1145) := '6C616365282F5C2E5B5E2E5D2A242F2C202222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C20225F2229202B20222E22202B20657874466F72286D696D6529203A20746869732E66696C654E616D65286D696D652C206B696E6429292C0A';
wwv_flow_imp.g_varchar2_table(1146) := '2020202020202020202020207472616E736372697074203D2070686F746F203F202222203A20746869732E726576696577546578742E76616C75652E7472696D28292E736C69636528302C204D41585F5452414E534352495054292C0A20202020202020';
wwv_flow_imp.g_varchar2_table(1147) := '2020202020736563203D2070686F746F203F206E756C6C203A20746869732E70656E64696E675365632C0A202020202020202020202020726F77203D207B206E616D653A206E616D652C206D696D653A206D696D652C206B696E643A206B696E642E746F';
wwv_flow_imp.g_varchar2_table(1148) := '55707065724361736528292C2073697A653A20626C6F622E73697A652C206475726174696F6E3A207365632C20626C6F623A20626C6F622C2075706C6F6164696E673A20302C207472616E7363726970743A207472616E7363726970742C0A2020202020';
wwv_flow_imp.g_varchar2_table(1149) := '20202020202020202020202020202077696474683A2070686F746F203F2070686F746F2E7769647468203A206E756C6C2C206865696768743A2070686F746F203F2070686F746F2E686569676874203A206E756C6C207D3B0A2020202020202020746869';
wwv_flow_imp.g_varchar2_table(1150) := '732E70656E64696E674E616D65203D206E616D653B0A2020202020202020746869732E73617665447261667428293B0A2020202020202020746869732E636C65617252657669657728293B0A2020202020202020746869732E70656E64696E67426C6F62';
wwv_flow_imp.g_varchar2_table(1151) := '203D206E756C6C3B0A2020202020202020746869732E736179282222293B0A2020202020202020746869732E6974656D732E7075736828726F77293B0A2020202020202020746869732E75706C6F6164696E67417564696F203D206B696E64203D3D3D20';
wwv_flow_imp.g_varchar2_table(1152) := '22617564696F223B0A2020202020202020746869732E7365745374617465282275706C6F6164696E6722293B0A2020202020202020746869732E72656E6465724C69737428293B0A2020202020202020746869732E75706C6F616428626C6F622C20726F';
wwv_flow_imp.g_varchar2_table(1153) := '77292E7468656E2866756E6374696F6E202872657329207B0A202020202020202020202020766172206265666F7265203D2073656C662E6A6F696E656428293B0A202020202020202020202020726F772E736571203D207265732E7365713B0A20202020';
wwv_flow_imp.g_varchar2_table(1154) := '2020202020202020726F772E6E616D65203D207265732E6E616D653B0A202020202020202020202020726F772E75706C6F6164696E67203D206E756C6C3B0A202020202020202020202020726F772E70656E64696E67203D20747275653B0A2020202020';
wwv_flow_imp.g_varchar2_table(1155) := '20202020202020696620287265732E7472616E73637269707429207B20726F772E7472616E736372697074203D207265732E7472616E7363726970743B207D0A20202020202020202020202073656C662E70656E64696E674E616D65203D206E756C6C3B';
wwv_flow_imp.g_varchar2_table(1156) := '0A20202020202020202020202073656C662E75706C6F61644E616D65203D206E756C6C3B0A20202020202020202020202073656C662E726177426C6F62203D206E756C6C3B0A20202020202020202020202073656C662E6661696C6564203D2066616C73';
wwv_flow_imp.g_varchar2_table(1157) := '653B0A20202020202020202020202073656C662E726576696577546578742E76616C7565203D2022223B0A20202020202020202020202073656C662E64726F70447261667428293B0A20202020202020202020202073656C662E73657453746174652822';
wwv_flow_imp.g_varchar2_table(1158) := '69646C6522293B0A20202020202020202020202073656C662E72656E6465724C69737428293B0A20202020202020202020202073656C662E777269746556616C7565286265666F72652C20726F77293B0A20202020202020202020202073656C662E666F';
wwv_flow_imp.g_varchar2_table(1159) := '6375734E65787428293B0A20202020202020202020202073656C662E6669726528227361766564222C207B207365713A207265732E7365712C206E616D653A207265732E6E616D652C206D696D65547970653A207265732E6D696D652C206B696E643A20';
wwv_flow_imp.g_varchar2_table(1160) := '7265732E6B696E642C2062797465733A207265732E73697A652C207365636F6E64733A207265732E6475726174696F6E2C0A20202020202020202020202020202020202020202020202020202020202020202077696474683A20726F772E77696474682C';
wwv_flow_imp.g_varchar2_table(1161) := '206865696768743A20726F772E6865696768742C207472616E7363726970743A20726F772E7472616E736372697074207D293B0A20202020202020207D292E63617463682866756E6374696F6E202865727229207B0A2020202020202020202020202F2F';
wwv_flow_imp.g_varchar2_table(1162) := '206B6565702069743A206261636B20746F207265766965772C20776974682054727920416761696E20616E6420446F776E6C6F61642028612070686F746F20636F6D6573206261636B20617320656469746564290A202020202020202020202020766172';
wwv_flow_imp.g_varchar2_table(1163) := '206D7367203D20657272202626206572722E73657373696F6E203F20747874282253455353494F4E5F454E4445442229203A20747874282255504C4F41445F4641494C4544222C2028657272202626206572722E6D65737361676529207C7C202222293B';
wwv_flow_imp.g_varchar2_table(1164) := '0A20202020202020202020202073656C662E6974656D732E73706C6963652873656C662E6974656D732E696E6465784F6628726F77292C2031293B0A20202020202020202020202073656C662E72656E6465724C69737428293B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(1165) := '20202073656C662E70656E64696E67426C6F62203D20626C6F623B0A20202020202020202020202073656C662E70656E64696E67536563203D207365633B0A20202020202020202020202073656C662E726576696577546578742E76616C7565203D2074';
wwv_flow_imp.g_varchar2_table(1166) := '72616E7363726970743B0A20202020202020202020202073656C662E6661696C6564203D20747275653B0A2020202020202020202020206966202870686F746F29207B0A2020202020202020202020202020202073656C662E70656E64696E674E616D65';
wwv_flow_imp.g_varchar2_table(1167) := '203D206E616D653B0A2020202020202020202020202020202073656C662E65644C6F616428626C6F62292E7468656E2866756E6374696F6E202829207B2073656C662E6661696C6564203D20747275653B2073656C662E73686F7752657669657728293B';
wwv_flow_imp.g_varchar2_table(1168) := '2073656C662E736179286D73672C20226572726F7222293B207D293B0A2020202020202020202020207D20656C7365207B0A2020202020202020202020202020202073656C662E73686F7752657669657728293B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1169) := '2073656C662E736179286D73672C20226572726F7222293B0A2020202020202020202020207D0A20202020202020202020202073656C662E6669726528226572726F72222C207B20726561736F6E3A20657272202626206572722E73657373696F6E203F';
wwv_flow_imp.g_varchar2_table(1170) := '202273657373696F6E22203A202275706C6F6164222C206D6573736167653A20657272202626206572722E6D657373616765207D293B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E6361';
wwv_flow_imp.g_varchar2_table(1171) := '6C6C203D2066756E6374696F6E20286461746129207B0A202020202020202076617220616A6178203D20746869732E6366672E616A61783B0A202020202020202072657475726E206E65772050726F6D6973652866756E6374696F6E20287265736F6C76';
wwv_flow_imp.g_varchar2_table(1172) := '652C2072656A65637429207B0A202020202020202020202020617065782E7365727665722E706C7567696E28616A61782C20646174612C207B2064617461547970653A20226A736F6E22207D292E7468656E2866756E6374696F6E202872657329207B0A';
wwv_flow_imp.g_varchar2_table(1173) := '2020202020202020202020202020202069662028726573202626207265732E6572726F7229207B0A20202020202020202020202020202020202020207661722065203D206E6577204572726F72287265732E6572726F72293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(1174) := '20202020202020202020652E73657373696F6E203D202F73657373696F6E2F692E74657374287265732E6572726F7229202626202F28657870697265647C656E6465647C696E76616C69647C74696D65643F203F6F7574292F692E74657374287265732E';
wwv_flow_imp.g_varchar2_table(1175) := '6572726F72293B0A202020202020202020202020202020202020202072656A6563742865293B0A202020202020202020202020202020207D20656C7365207B0A20202020202020202020202020202020202020207265736F6C766528726573207C7C207B';
wwv_flow_imp.g_varchar2_table(1176) := '7D293B0A202020202020202020202020202020207D0A2020202020202020202020207D2C2066756E6374696F6E20287868722C207374617475732C2065727229207B0A20202020202020202020202020202020766172206D7367203D2028786872202626';
wwv_flow_imp.g_varchar2_table(1177) := '207868722E726573706F6E73654A534F4E202626207868722E726573706F6E73654A534F4E2E6572726F7229207C7C2028786872202626207868722E737461747573203D3D3D2030203F2074787428224E4554574F524B2229203A20657272207C7C2073';
wwv_flow_imp.g_varchar2_table(1178) := '7461747573207C7C2074787428224E4554574F524B2229292C0A202020202020202020202020202020202020202065203D206E6577204572726F72286D7367293B0A202020202020202020202020202020202F2F20616E20657870697265642073657373';
wwv_flow_imp.g_varchar2_table(1179) := '696F6E20616E737765727320776974682061207369676E2D696E207061676520286E6F74204A534F4E29206F7220343031202F203430330A20202020202020202020202020202020652E73657373696F6E203D20212178687220262620287868722E7374';
wwv_flow_imp.g_varchar2_table(1180) := '61747573203D3D3D20343031207C7C207868722E737461747573203D3D3D20343033207C7C0A202020202020202020202020202020202020202028737461747573203D3D3D20227061727365726572726F7222202626202F3C68746D6C7C6C6F67696E7C';
wwv_flow_imp.g_varchar2_table(1181) := '7369676E2E3F696E2F692E74657374287868722E726573706F6E736554657874207C7C2022222929207C7C202F73657373696F6E2F692E74657374286D736729293B0A2020202020202020202020202020202072656A6563742865293B0A202020202020';
wwv_flow_imp.g_varchar2_table(1182) := '2020202020207D293B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E75706C6F6164203D2066756E6374696F6E2028626C6F622C20726F7729207B0A20202020202020207661722073656C';
wwv_flow_imp.g_varchar2_table(1183) := '66203D20746869732C20746F6B203D20746F6B656E28292C207061727473203D204D6174682E6D617828312C204D6174682E6365696C28626C6F622E73697A65202F20504152545F425954455329292C206E657874203D20302C20646F6E65203D20303B';
wwv_flow_imp.g_varchar2_table(1184) := '0A202020202020202076617220776F726B6572203D2066756E6374696F6E202829207B0A202020202020202020202020696620286E657874203E3D20706172747329207B2072657475726E2050726F6D6973652E7265736F6C766528293B207D0A202020';
wwv_flow_imp.g_varchar2_table(1185) := '2020202020202020207661722069203D206E6578742B2B3B0A20202020202020202020202072657475726E207265616442617365363428626C6F622E736C6963652869202A20504152545F42595445532C204D6174682E6D696E28626C6F622E73697A65';
wwv_flow_imp.g_varchar2_table(1186) := '2C202869202B203129202A20504152545F42595445532929292E7468656E2866756E6374696F6E202862363429207B0A2020202020202020202020202020202076617220663031203D205B5D3B0A20202020202020202020202020202020666F72202876';
wwv_flow_imp.g_varchar2_table(1187) := '61722070203D20303B2070203C206236342E6C656E6774683B2070202B3D2050494543455F434841525329207B206630312E70757368286236342E73756273747228702C2050494543455F434841525329293B207D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1188) := '202072657475726E2073656C662E63616C6C287B207830313A202250415254222C207830323A20746F6B2C207830333A20692C206630313A20663031207D293B0A2020202020202020202020207D292E7468656E2866756E6374696F6E202829207B0A20';
wwv_flow_imp.g_varchar2_table(1189) := '202020202020202020202020202020646F6E652B2B3B0A20202020202020202020202020202020726F772E75706C6F6164696E67203D204D6174682E726F756E6428646F6E65202F207061727473202A20313030293B0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1190) := '20202073656C662E72656E64657250726F677265737328726F77293B0A2020202020202020202020202020202072657475726E20776F726B657228293B0A2020202020202020202020207D293B0A20202020202020207D3B0A2020202020202020766172';
wwv_flow_imp.g_varchar2_table(1191) := '20706F6F6C203D205B5D3B0A2020202020202020666F7220287661722077203D20303B2077203C204D6174682E6D696E28504152414C4C454C2C207061727473293B20772B2B29207B20706F6F6C2E7075736828776F726B65722829293B207D0A202020';
wwv_flow_imp.g_varchar2_table(1192) := '202020202072657475726E2050726F6D6973652E616C6C28706F6F6C292E7468656E2866756E6374696F6E202829207B0A20202020202020202020202072657475726E2073656C662E63616C6C287B207830313A202246494E495348222C207830323A20';
wwv_flow_imp.g_varchar2_table(1193) := '746F6B2C207830343A2070617274732C0A202020202020202020202020202020207830353A2073656C662E6974656D732E66696C7465722866756E6374696F6E20287229207B2072657475726E20722E7365713B207D292E6D61702866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(1194) := '20287229207B2072657475726E20722E7365713B207D292E6A6F696E28223A22292C0A202020202020202020202020202020207830363A2073656C662E6C616E672C0A202020202020202020202020202020207830333A204A534F4E2E737472696E6769';
wwv_flow_imp.g_varchar2_table(1195) := '6679287B206E616D653A20726F772E6E616D652C206D696D653A20726F772E6D696D652C206475726174696F6E3A20726F772E6475726174696F6E203F204D6174682E726F756E6428726F772E6475726174696F6E202A20313029202F203130203A206E';
wwv_flow_imp.g_varchar2_table(1196) := '756C6C2C0A202020202020202020202020202020202020202020202020202020202020202020202020202077696474683A20726F772E7769647468207C7C206E756C6C2C206865696768743A20726F772E686569676874207C7C206E756C6C2C20747261';
wwv_flow_imp.g_varchar2_table(1197) := '6E7363726970743A20726F772E7472616E736372697074207C7C206E756C6C207D29207D293B0A20202020202020207D293B0A202020207D3B0A0A202020202F2F2076616C75652C20616E6420746865205472616E736372697074204974656D3A207468';
wwv_flow_imp.g_varchar2_table(1198) := '65207472616E7363726970747320617265206F6E6C792072657772697474656E207768696C6520746865207573657220686173206E6F7420656469746564207468656D3B0A202020202F2F20616674657220616E20656469742C2061206E657720747261';
wwv_flow_imp.g_varchar2_table(1199) := '6E7363726970742069732061646465642061742074686520656E6420616E64206E6F7468696E672069732074616B656E20617761790A202020205265636F726465722E70726F746F747970652E777269746556616C7565203D2066756E6374696F6E2028';
wwv_flow_imp.g_varchar2_table(1200) := '6265666F72652C20616464656429207B0A20202020202020207661722076203D20746869732E6974656D732E66696C7465722866756E6374696F6E20287229207B2072657475726E20722E7365713B207D292E6D61702866756E6374696F6E2028722920';
wwv_flow_imp.g_varchar2_table(1201) := '7B2072657475726E20722E7365713B207D292E6A6F696E28223A22293B0A202020202020202069662028746869732E696E7075742E76616C756520213D3D207629207B0A202020202020202020202020746869732E696E7075742E76616C7565203D2076';
wwv_flow_imp.g_varchar2_table(1202) := '3B0A2020202020202020202020202428746869732E696E707574292E7472696767657228226368616E676522293B0A20202020202020207D0A2020202020202020766172207469203D20746869732E6366672E7472616E7363726970744974656D202626';
wwv_flow_imp.g_varchar2_table(1203) := '20617065782E6974656D28746869732E6366672E7472616E7363726970744974656D293B0A20202020202020206966202874692026262074692E6E6F646529207B0A20202020202020202020202076617220637572203D20537472696E672874692E6765';
wwv_flow_imp.g_varchar2_table(1204) := '7456616C75652829207C7C202222292C206E6F77203D20746869732E6A6F696E656428293B0A202020202020202020202020696620286375722E7472696D2829203D3D3D20537472696E67286265666F7265207C7C202222292E7472696D282929207B0A';
wwv_flow_imp.g_varchar2_table(1205) := '2020202020202020202020202020202074692E73657456616C7565286E6F77293B0A2020202020202020202020207D20656C7365206966202861646465642026262061646465642E7472616E73637269707429207B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1206) := '202074692E73657456616C7565286375722E7265706C616365282F5C732B242F2C20222229202B20286375722E7472696D2829203F20225C6E5C6E22203A20222229202B2061646465642E7472616E736372697074293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1207) := '7D0A20202020202020207D0A202020207D3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D206C697374206F6620';
wwv_flow_imp.g_varchar2_table(1208) := '7265636F7264696E67730A202020205265636F726465722E70726F746F747970652E6D6564696155726C203D2066756E6374696F6E20287229207B0A202020202020202069662028722E626C6F6229207B0A202020202020202020202020696620282172';
wwv_flow_imp.g_varchar2_table(1209) := '2E75726C29207B20722E75726C203D2055524C2E6372656174654F626A65637455524C28722E626C6F62293B207D0A20202020202020202020202072657475726E2050726F6D6973652E7265736F6C766528722E75726C293B0A20202020202020207D0A';
wwv_flow_imp.g_varchar2_table(1210) := '202020202020202069662028722E75726C29207B2072657475726E2050726F6D6973652E7265736F6C766528722E75726C293B207D0A20202020202020202F2F206665746368207468652077686F6C652066696C65206F6E63653A205361666172692063';
wwv_flow_imp.g_varchar2_table(1211) := '616E6E6F742073747265616D206D6564696120776974686F757420627974652072616E6765730A202020202020202076617220737263203D20617065782E7365727665722E706C7567696E55726C28746869732E6366672E616A61782C20722E726F7720';
wwv_flow_imp.g_varchar2_table(1212) := '3F207B207830313A20225341564544222C207830323A20722E726F77207D203A207B207830313A2022474554222C207830323A20722E736571207D293B0A202020202020202072657475726E206665746368287372632C207B2063726564656E7469616C';
wwv_flow_imp.g_varchar2_table(1213) := '733A202273616D652D6F726967696E22207D292E7468656E2866756E6374696F6E202872657329207B0A20202020202020202020202069662028217265732E6F6B29207B207468726F77206E6577204572726F72287265732E737461747573202B202220';
wwv_flow_imp.g_varchar2_table(1214) := '22202B207265732E73746174757354657874293B207D0A20202020202020202020202072657475726E207265732E626C6F6228293B0A20202020202020207D292E7468656E2866756E6374696F6E20286229207B0A202020202020202020202020722E75';
wwv_flow_imp.g_varchar2_table(1215) := '726C203D2055524C2E6372656174654F626A65637455524C28622E74797065203F2062203A206E657720426C6F62285B625D2C207B20747970653A20722E6D696D65207C7C202222207D29293B0A20202020202020202020202072657475726E20722E75';
wwv_flow_imp.g_varchar2_table(1216) := '726C3B0A20202020202020207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E72656E64657250726F6772657373203D2066756E6374696F6E20287229207B0A20202020202020206966202821722E6C6929207B20';
wwv_flow_imp.g_varchar2_table(1217) := '72657475726E3B207D0A202020202020202076617220626172203D20722E6C692E717565727953656C6563746F7228222E6D706C75732D726F772D70726F6772657373207370616E22292C206D657461203D20722E6C692E717565727953656C6563746F';
wwv_flow_imp.g_varchar2_table(1218) := '7228222E6D706C75732D726F772D6D65746122293B0A20202020202020206966202862617229207B206261722E7374796C652E7769647468203D2028722E75706C6F6164696E67207C7C203029202B202225223B207D0A2020202020202020696620286D';
wwv_flow_imp.g_varchar2_table(1219) := '65746129207B206D6574612E74657874436F6E74656E74203D20722E75706C6F6164696E67203E3D2031303020262620746869732E6366672E7472616E736372697074696F6E203D3D3D20225345525645522220262620722E6B696E64203D3D3D202241';
wwv_flow_imp.g_varchar2_table(1220) := '5544494F22203F2074787428225452414E5343524942494E475F5345525645522229202B20222E2E2E22203A20747874282255504C4F41445F50524F4752455353222C20722E75706C6F6164696E67207C7C2030293B207D0A202020207D3B0A0A202020';
wwv_flow_imp.g_varchar2_table(1221) := '205265636F726465722E70726F746F747970652E72656E6465724C697374203D2066756E6374696F6E202829207B0A20202020202020207661722073656C66203D20746869732C20726F203D20746869732E6366672E726561644F6E6C79207C7C207468';
wwv_flow_imp.g_varchar2_table(1222) := '69732E64697361626C65642C0A202020202020202020202020726F7773203D20746869732E73617665642E6D61702866756E6374696F6E20287329207B20732E69735361766564203D20747275653B20732E6B696E64203D20732E6B696E64207C7C206B';
wwv_flow_imp.g_varchar2_table(1223) := '696E644F6628732E6D696D65293B2072657475726E20733B207D292E636F6E63617428746869732E6974656D73293B0A2020202020202020746869732E6C6973742E696E6E657248544D4C203D2022223B0A2020202020202020726F77732E666F724561';
wwv_flow_imp.g_varchar2_table(1224) := '63682866756E6374696F6E2028722C2069647829207B0A20202020202020202020202076617220766964656F203D20722E6B696E64203D3D3D2022564944454F222C20696D616765203D20722E6B696E64203D3D3D2022494D414745222C0A2020202020';
wwv_flow_imp.g_varchar2_table(1225) := '20202020202020202020206E616D65203D20722E6E616D65207C7C202874787428722E6B696E64207C7C2022415544494F2229202B20222022202B2028696478202B203129292C0A202020202020202020202020202020206D657461203D205B722E6475';
wwv_flow_imp.g_varchar2_table(1226) := '726174696F6E203F20666D7454696D6528722E6475726174696F6E29203A206E756C6C2C20722E776964746820262620722E686569676874203F20747874282250484F544F5F4D455441222C20722E77696474682C20722E68656967687429203A206E75';
wwv_flow_imp.g_varchar2_table(1227) := '6C6C2C0A202020202020202020202020202020202020202020202020722E73697A65203F20666D74427974657328722E73697A6529203A206E756C6C5D2E66696C74657228426F6F6C65616E292E6A6F696E282220C2B72022292C0A2020202020202020';
wwv_flow_imp.g_varchar2_table(1228) := '202020202020202075706C6F6164696E67203D20722E75706C6F6164696E6720213D3D20756E646566696E656420262620722E75706C6F6164696E6720213D3D206E756C6C2C0A2020202020202020202020202020202069636F203D20656C2822737061';
wwv_flow_imp.g_varchar2_table(1229) := '6E222C20226D706C75732D726F772D69636F222C207B2022617269612D68696464656E223A20227472756522207D2C205B656C28227370616E222C202266612022202B2028696D616765203F202266612D63616D65726122203A20766964656F203F2022';
wwv_flow_imp.g_varchar2_table(1230) := '66612D766964656F2D63616D65726122203A202266612D6D6963726F70686F6E652229295D292C0A2020202020202020202020202020202062506C6179203D20696D616765203F2069636F6E427574746F6E28226D706C75732D722D706C6179222C2022';
wwv_flow_imp.g_varchar2_table(1231) := '66612D657965222C20747874282256494557222929203A2069636F6E427574746F6E28226D706C75732D722D706C6179222C202266612D706C6179222C207478742822504C41592229292C0A202020202020202020202020202020206244656C203D2069';
wwv_flow_imp.g_varchar2_table(1232) := '636F6E427574746F6E28226D706C75732D722D64656C222C202266612D74726173682D6F222C20747874282244454C4554452229292C0A2020202020202020202020202020202061446F776E203D20656C282261222C2022742D427574746F6E20742D42';
wwv_flow_imp.g_varchar2_table(1233) := '7574746F6E2D2D736D616C6C20742D427574746F6E2D2D6E6F554920742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D2D69636F6E206D706C75732D722D646F776E222C0A202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1234) := '2020207B20687265663A202223222C207469746C653A207478742822444F574E4C4F414422292C2022617269612D6C6162656C223A207478742822444F574E4C4F414422292C20646F776E6C6F61643A206E616D65207D2C205B666149636F6E28226661';
wwv_flow_imp.g_varchar2_table(1235) := '2D646F776E6C6F616422295D292C0A20202020202020202020202020202020706C61796572203D20656C2822646976222C20226D706C75732D726F772D706C61796572222C207B2068696464656E3A2074727565207D292C0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(1236) := '20202020206C69203D20656C28226C69222C20226D706C75732D726F7722202B202875706C6F6164696E67203F20222069732D75706C6F6164696E6722203A20222229202B2028696D616765203F2022206D706C75732D726F772D2D696D61676522203A';
wwv_flow_imp.g_varchar2_table(1237) := '202222292C206E756C6C2C205B0A202020202020202020202020202020202020202069636F2C0A2020202020202020202020202020202020202020656C2822646976222C20226D706C75732D726F772D6D61696E222C206E756C6C2C205B0A2020202020';
wwv_flow_imp.g_varchar2_table(1238) := '20202020202020202020202020202020202020656C28227370616E222C20226D706C75732D726F772D6E616D65222C207B20746578743A206E616D652C207469746C653A206E616D65207D292C0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1239) := '2020656C28227370616E222C20226D706C75732D726F772D6D657461222C207B20746578743A206D657461207D292C0A202020202020202020202020202020202020202020202020722E69735361766564203F20656C28227370616E222C20226D706C75';
wwv_flow_imp.g_varchar2_table(1240) := '732D746167206D706C75732D7461672D2D7361766564222C207B20746578743A20747874282253415645442229207D29203A2028722E7365712026262021726F203F20656C28227370616E222C20226D706C75732D746167222C207B20746578743A2074';
wwv_flow_imp.g_varchar2_table(1241) := '7874282250454E44494E472229207D29203A206E756C6C292C0A20202020202020202020202020202020202020202020202075706C6F6164696E67203F20656C28227370616E222C20226D706C75732D726F772D70726F6772657373222C206E756C6C2C';
wwv_flow_imp.g_varchar2_table(1242) := '205B656C28227370616E22295D29203A206E756C6C0A20202020202020202020202020202020202020205D292C0A2020202020202020202020202020202020202020656C28227370616E222C20226D706C75732D726F772D62746E73222C206E756C6C2C';
wwv_flow_imp.g_varchar2_table(1243) := '205B0A202020202020202020202020202020202020202020202020722E736571207C7C20722E726F77203F2062506C6179203A206E756C6C2C0A20202020202020202020202020202020202020202020202028722E736571207C7C20722E726F77292026';
wwv_flow_imp.g_varchar2_table(1244) := '262073656C662E6861732822646F776E6C6F61642229203F2061446F776E203A206E756C6C2C0A202020202020202020202020202020202020202020202020722E7365712026262021722E697353617665642026262021726F203F206244656C203A206E';
wwv_flow_imp.g_varchar2_table(1245) := '756C6C0A20202020202020202020202020202020202020205D292C0A2020202020202020202020202020202020202020722E7472616E736372697074203F20656C2822646976222C20226D706C75732D726F772D74657874222C207B20746578743A2072';
wwv_flow_imp.g_varchar2_table(1246) := '2E7472616E7363726970742C207469746C653A20722E7472616E736372697074207D29203A206E756C6C2C0A2020202020202020202020202020202020202020706C617965720A202020202020202020202020202020205D293B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(1247) := '202020722E6C69203D206C693B0A2020202020202020202020202F2F20612070686F746F206164646564206F6E207468697320706167652073686F777320697473207468756D626E61696C206174206F6E63650A20202020202020202020202069662028';
wwv_flow_imp.g_varchar2_table(1248) := '696D6167652026262028722E626C6F62207C7C20722E75726C2929207B0A2020202020202020202020202020202073656C662E6D6564696155726C2872292E7468656E2866756E6374696F6E20287529207B2069636F2E696E6E657248544D4C203D2022';
wwv_flow_imp.g_varchar2_table(1249) := '223B2069636F2E617070656E644368696C6428656C2822696D67222C20226D706C75732D726F772D7468756D62222C207B207372633A20752C20616C743A202222207D29293B207D293B0A2020202020202020202020207D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(1250) := '2062506C61792E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E202829207B2073656C662E746F67676C65506C617928722C2062506C61792C20706C61796572293B207D293B0A2020202020202020202020206144';
wwv_flow_imp.g_varchar2_table(1251) := '6F776E2E6164644576656E744C697374656E65722822636C69636B222C2066756E6374696F6E20286529207B0A202020202020202020202020202020206966202861446F776E2E676574417474726962757465282268726566222920213D3D2022232229';
wwv_flow_imp.g_varchar2_table(1252) := '207B2072657475726E3B207D0A20202020202020202020202020202020652E70726576656E7444656661756C7428293B0A2020202020202020202020202020202073656C662E6D6564696155726C2872292E7468656E2866756E6374696F6E2028752920';
wwv_flow_imp.g_varchar2_table(1253) := '7B2061446F776E2E68726566203D20753B2061446F776E2E636C69636B28293B207D293B0A2020202020202020202020207D293B0A2020202020202020202020206244656C2E6164644576656E744C697374656E65722822636C69636B222C2066756E63';
wwv_flow_imp.g_varchar2_table(1254) := '74696F6E202829207B2073656C662E72656D6F76652872293B207D293B0A20202020202020202020202073656C662E6C6973742E617070656E644368696C64286C69293B0A2020202020202020202020206966202875706C6F6164696E6729207B207365';
wwv_flow_imp.g_varchar2_table(1255) := '6C662E72656E64657250726F67726573732872293B207D0A20202020202020207D293B0A202020202020202073686F7728746869732E6C6973742C20726F77732E6C656E677468203E2030293B0A202020207D3B0A0A202020205265636F726465722E70';
wwv_flow_imp.g_varchar2_table(1256) := '726F746F747970652E746F67676C65506C6179203D2066756E6374696F6E2028722C20622C20626F7829207B0A20202020202020207661722073656C66203D20746869732C20696D616765203D20722E6B696E64203D3D3D2022494D414745222C207365';
wwv_flow_imp.g_varchar2_table(1257) := '7449636F6E203D2066756E6374696F6E202869636F6E2C206C6162656C29207B0A202020202020202020202020622E717565727953656C6563746F7228222E742D49636F6E22292E636C6173734E616D65203D2022742D49636F6E2066612022202B2069';
wwv_flow_imp.g_varchar2_table(1258) := '636F6E3B0A202020202020202020202020622E7469746C65203D206C6162656C3B0A202020202020202020202020622E7365744174747269627574652822617269612D6C6162656C222C206C6162656C293B0A20202020202020207D3B0A202020202020';
wwv_flow_imp.g_varchar2_table(1259) := '20206966202821626F782E68696464656E29207B0A202020202020202020202020766172206F6C64203D20626F782E717565727953656C6563746F722822617564696F2C766964656F22293B0A202020202020202020202020696620286F6C6429207B20';
wwv_flow_imp.g_varchar2_table(1260) := '6F6C642E706175736528293B207D0A202020202020202020202020626F782E68696464656E203D20747275653B0A202020202020202020202020626F782E696E6E657248544D4C203D2022223B0A20202020202020202020202073657449636F6E28696D';
wwv_flow_imp.g_varchar2_table(1261) := '616765203F202266612D65796522203A202266612D706C6179222C20696D616765203F207478742822564945572229203A207478742822504C41592229293B0A20202020202020202020202072657475726E3B0A20202020202020207D0A202020202020';
wwv_flow_imp.g_varchar2_table(1262) := '2020622E64697361626C6564203D20747275653B0A2020202020202020746869732E6D6564696155726C2872292E7468656E2866756E6374696F6E20287529207B0A20202020202020202020202076617220766964656F203D20722E6B696E64203D3D3D';
wwv_flow_imp.g_varchar2_table(1263) := '2022564944454F222C206D3B0A202020202020202020202020626F782E696E6E657248544D4C203D2022223B0A20202020202020202020202069662028696D61676529207B0A202020202020202020202020202020206D203D20656C2822696D67222C20';
wwv_flow_imp.g_varchar2_table(1264) := '226D706C75732D70686F746F222C207B207372633A20752C20616C743A20722E6E616D65207C7C202222207D293B0A20202020202020202020202020202020626F782E617070656E644368696C64286D293B0A2020202020202020202020202020202076';
wwv_flow_imp.g_varchar2_table(1265) := '6172207468756D62203D20722E6C6920262620722E6C692E717565727953656C6563746F7228222E6D706C75732D726F772D69636F22293B0A20202020202020202020202020202020696620287468756D6220262620217468756D622E71756572795365';
wwv_flow_imp.g_varchar2_table(1266) := '6C6563746F722822696D67222929207B207468756D622E696E6E657248544D4C203D2022223B207468756D622E617070656E644368696C6428656C2822696D67222C20226D706C75732D726F772D7468756D62222C207B207372633A20752C20616C743A';
wwv_flow_imp.g_varchar2_table(1267) := '202222207D29293B207D0A2020202020202020202020207D20656C7365207B0A202020202020202020202020202020206D203D20656C28766964656F203F2022766964656F22203A2022617564696F222C20226D706C75732D6D65646961222C207B2063';
wwv_flow_imp.g_varchar2_table(1268) := '6F6E74726F6C733A20747275652C20706C617973696E6C696E653A20766964656F203F2074727565203A206E756C6C2C207072656C6F61643A20226D6574616461746122207D293B0A202020202020202020202020202020206D2E6164644576656E744C';
wwv_flow_imp.g_varchar2_table(1269) := '697374656E65722822706C6179222C2066756E6374696F6E202829207B20617564696F53657373696F6E2822706C61796261636B22293B207D293B0A202020202020202020202020202020206669784475726174696F6E286D293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(1270) := '20202020202020206D2E737263203D20753B0A20202020202020202020202020202020626F782E617070656E644368696C64286D293B0A202020202020202020202020202020206D2E706C617928292E63617463682866756E6374696F6E202829207B20';
wwv_flow_imp.g_varchar2_table(1271) := '2F2A20757365722063616E20707265737320706C6179202A2F207D293B0A2020202020202020202020207D0A202020202020202020202020626F782E68696464656E203D2066616C73653B0A20202020202020202020202073657449636F6E282266612D';
wwv_flow_imp.g_varchar2_table(1272) := '63686576726F6E2D7570222C20696D616765203F207478742822484944452229203A207478742822484944455F504C415945522229293B0A20202020202020207D292E63617463682866756E6374696F6E20286529207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1273) := '73656C662E736179287478742822504C41595F4641494C4544222C20652E6D657373616765292C20226572726F7222293B0A20202020202020207D292E66696E616C6C792866756E6374696F6E202829207B20622E64697361626C6564203D2066616C73';
wwv_flow_imp.g_varchar2_table(1274) := '653B207D293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E72656D6F7665203D2066756E6374696F6E20287229207B0A20202020202020207661722073656C66203D20746869732C0A20202020202020202020202067';
wwv_flow_imp.g_varchar2_table(1275) := '6F203D2066756E6374696F6E202829207B0A2020202020202020202020202020202073656C662E63616C6C287B207830313A202244454C455445222C207830323A20722E736571207D292E7468656E2866756E6374696F6E202829207B0A202020202020';
wwv_flow_imp.g_varchar2_table(1276) := '2020202020202020202020202020766172206265666F7265203D2073656C662E6A6F696E656428293B0A202020202020202020202020202020202020202069662028722E75726C29207B2055524C2E7265766F6B654F626A65637455524C28722E75726C';
wwv_flow_imp.g_varchar2_table(1277) := '293B207D0A202020202020202020202020202020202020202073656C662E6974656D732E73706C6963652873656C662E6974656D732E696E6465784F662872292C2031293B0A202020202020202020202020202020202020202073656C662E72656E6465';
wwv_flow_imp.g_varchar2_table(1278) := '724C69737428293B0A202020202020202020202020202020202020202073656C662E777269746556616C7565286265666F72652C206E756C6C293B0A202020202020202020202020202020202020202073656C662E73796E6328293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(1279) := '2020202020202020202020202073656C662E666F6375734E65787428293B0A202020202020202020202020202020202020202073656C662E66697265282264656C657465222C207B207365713A20722E7365712C206E616D653A20722E6E616D65207D29';
wwv_flow_imp.g_varchar2_table(1280) := '3B0A202020202020202020202020202020207D292E63617463682866756E6374696F6E20286529207B2073656C662E73617928652E73657373696F6E203F20747874282253455353494F4E5F454E4445442229203A20652E6D6573736167652C20226572';
wwv_flow_imp.g_varchar2_table(1281) := '726F7222293B207D293B0A2020202020202020202020207D3B0A202020202020202069662028746869732E6861732822636F6E6669726D44656C657465222929207B0A202020202020202020202020617065782E6D6573736167652E636F6E6669726D28';
wwv_flow_imp.g_varchar2_table(1282) := '7478742822434F4E4649524D5F44454C45544522292C2066756E6374696F6E20286F6B29207B20696620286F6B29207B20676F28293B207D207D293B0A20202020202020207D20656C7365207B0A202020202020202020202020676F28293B0A20202020';
wwv_flow_imp.g_varchar2_table(1283) := '202020207D0A202020207D3B0A0A202020202F2F2076616C7565207365742066726F6D206F7574736964652028652E672E205365742056616C7565202F20436C656172293A206B656570206F6E6C7920746865207265636F7264696E6773207374696C6C';
wwv_flow_imp.g_varchar2_table(1284) := '206E616D656420696E2069740A202020205265636F726465722E70726F746F747970652E73657456616C7565203D2066756E6374696F6E20287629207B0A2020202020202020766172206B656570203D20537472696E672876207C7C202222292E73706C';
wwv_flow_imp.g_varchar2_table(1285) := '697428223A22293B0A2020202020202020746869732E6974656D73203D20746869732E6974656D732E66696C7465722866756E6374696F6E20287229207B2072657475726E20722E736571202626206B6565702E696E6465784F6628537472696E672872';
wwv_flow_imp.g_varchar2_table(1286) := '2E7365712929203E3D20303B207D293B0A2020202020202020746869732E696E7075742E76616C7565203D20746869732E6974656D732E6D61702866756E6374696F6E20287229207B2072657475726E20722E7365713B207D292E6A6F696E28223A2229';
wwv_flow_imp.g_varchar2_table(1287) := '3B0A2020202020202020746869732E72656E6465724C69737428293B0A2020202020202020746869732E73796E6328293B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E62757379203D2066756E6374696F6E20282920';
wwv_flow_imp.g_varchar2_table(1288) := '7B0A202020202020202072657475726E205B226F70656E696E67222C2022636F756E74646F776E222C20227265636F7264696E67222C2022706175736564222C202273746F7070696E67222C2022726576696577222C202275706C6F6164696E67225D2E';
wwv_flow_imp.g_varchar2_table(1289) := '696E6465784F6628746869732E737461746529203E3D20303B0A202020207D3B0A0A202020205265636F726465722E70726F746F747970652E73657444697361626C6564203D2066756E6374696F6E20286429207B0A2020202020202020746869732E64';
wwv_flow_imp.g_varchar2_table(1290) := '697361626C6564203D202121643B0A2020202020202020696620286420262620746869732E62757379282920262620746869732E737461746520213D3D202275706C6F6164696E672229207B0A20202020202020202020202069662028746869732E7265';
wwv_flow_imp.g_varchar2_table(1291) := '6329207B20746869732E7265632E6F6E73746F70203D206E756C6C3B20747279207B20746869732E7265632E73746F7028293B207D20636174636820286529207B202F2A2073746F70706564202A2F207D20746869732E726563203D206E756C6C3B207D';
wwv_flow_imp.g_varchar2_table(1292) := '0A202020202020202020202020636C656172496E74657276616C28746869732E7469636B293B0A202020202020202020202020636C656172496E74657276616C28746869732E636454696D6572293B0A202020202020202020202020746869732E63616E';
wwv_flow_imp.g_varchar2_table(1293) := '63656C6C6564203D20747275653B0A202020202020202020202020746869732E73747441626F727428293B0A202020202020202020202020746869732E72656C6561736528293B0A202020202020202020202020746869732E636C656172526576696577';
wwv_flow_imp.g_varchar2_table(1294) := '28293B0A202020202020202020202020746869732E7374617465203D202269646C65223B0A20202020202020207D0A2020202020202020746869732E72656E6465724C69737428293B0A2020202020202020746869732E73796E6328293B0A202020207D';
wwv_flow_imp.g_varchar2_table(1295) := '3B0A0A202020202F2F202D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D207075626C69630A2020202066756E6374696F6E20696E697428';
wwv_flow_imp.g_varchar2_table(1296) := '6366672C20696E6974466E29207B0A202020202020202069662028747970656F6620696E6974466E203D3D3D202266756E6374696F6E2229207B20636667203D20696E6974466E2863666729207C7C206366673B207D0A20202020202020206966202863';
wwv_flow_imp.g_varchar2_table(1297) := '66672E746578747329207B20242E657874656E6428544558542C206366672E7465787473293B207D0A202020202020202076617220726563203D206E6577205265636F7264657228636667292C20696E707574203D207265632E696E7075743B0A202020';
wwv_flow_imp.g_varchar2_table(1298) := '2020202020696E7374616E6365735B6366672E6974656D5D203D207265633B0A20202020202020207265632E726F6F742E7365744174747269627574652822646174612D7374617465222C202269646C6522293B0A0A2020202020202020617065782E69';
wwv_flow_imp.g_varchar2_table(1299) := '74656D2E637265617465286366672E6974656D2C207B0A20202020202020202020202067657456616C75653A2066756E6374696F6E202829207B2072657475726E20696E7075742E76616C75653B207D2C0A20202020202020202020202073657456616C';
wwv_flow_imp.g_varchar2_table(1300) := '75653A2066756E6374696F6E20287629207B207265632E73657456616C75652876293B207D2C0A20202020202020202020202069734368616E6765643A2066756E6374696F6E202829207B2072657475726E20696E7075742E76616C756520213D3D2072';
wwv_flow_imp.g_varchar2_table(1301) := '65632E696E697469616C207C7C207265632E6275737928293B207D2C0A202020202020202020202020656E61626C653A2066756E6374696F6E202829207B207265632E73657444697361626C65642866616C7365293B207D2C0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(1302) := '202064697361626C653A2066756E6374696F6E202829207B207265632E73657444697361626C65642874727565293B207D2C0A202020202020202020202020697344697361626C65643A2066756E6374696F6E202829207B2072657475726E207265632E';
wwv_flow_imp.g_varchar2_table(1303) := '64697361626C65643B207D2C0A202020202020202020202020736574466F637573546F3A2066756E6374696F6E202829207B2072657475726E2024287265632E726F6F74292E66696E642822627574746F6E3A76697369626C653A656E61626C65642229';
wwv_flow_imp.g_varchar2_table(1304) := '2E666972737428293B207D2C0A202020202020202020202020646973706C617956616C7565466F723A2066756E6374696F6E202829207B2072657475726E207265632E6974656D732E6D61702866756E6374696F6E20287229207B2072657475726E2072';
wwv_flow_imp.g_varchar2_table(1305) := '2E6E616D653B207D292E6A6F696E28222C2022293B207D0A20202020202020207D293B0A202020207D0A0A202020202F2F2041207265636F7264696E672074686174206973207374696C6C2072756E6E696E67206F72206E6F7420757365642079657420';
wwv_flow_imp.g_varchar2_table(1306) := '626C6F636B73207468652070616765207375626D6974202D2065786365707420666F72207468652072657175657374730A202020202F2F206C697374656420696E2022416C6C6F77205375626D697420666F72205265717565737473222028652E672E20';
wwv_flow_imp.g_varchar2_table(1307) := '43414E43454C2C2044454C455445292C2077686963682064726F702074686520756E66696E6973686564207265636F7264696E672E0A202020202428646F63756D656E74292E6F6E2822617065786265666F7265706167657375626D6974222C2066756E';
wwv_flow_imp.g_varchar2_table(1308) := '6374696F6E2028652C207265717565737429207B0A20202020202020204F626A6563742E6B65797328696E7374616E636573292E666F72456163682866756E6374696F6E20286B29207B0A2020202020202020202020207661722072203D20696E737461';
wwv_flow_imp.g_varchar2_table(1309) := '6E6365735B6B5D2C20616C6C6F776564203D20537472696E6728722E6366672E616C6C6F775265717565737473207C7C202222292E746F55707065724361736528292E73706C6974282F5B5C732C3A5D2B2F293B0A202020202020202020202020696620';
wwv_flow_imp.g_varchar2_table(1310) := '2821646F63756D656E742E626F64792E636F6E7461696E7328722E726F6F7429207C7C2021722E62757379282929207B2072657475726E3B207D0A202020202020202020202020696620287265717565737420262620616C6C6F7765642E696E6465784F';
wwv_flow_imp.g_varchar2_table(1311) := '6628537472696E672872657175657374292E746F557070657243617365282929203E3D203029207B0A202020202020202020202020202020202F2F2074686520496E646578656444422064656C657465206D6179206E6F742066696E697368206265666F';
wwv_flow_imp.g_varchar2_table(1312) := '726520746865207061676520756E6C6F6164733A206C656176652061206E6F746520666F7220746865206E657874206C6F616420746F6F0A20202020202020202020202020202020747279207B2073657373696F6E53746F726167652E7365744974656D';
wwv_flow_imp.g_varchar2_table(1313) := '28226D706C75732D6E6F64726166743A22202B20722E64726166744B65792C20223122293B207D20636174636820287829207B202F2A206E6F2073746F72616765202A2F207D0A20202020202020202020202020202020722E64726F7044726166742829';
wwv_flow_imp.g_varchar2_table(1314) := '3B0A2020202020202020202020202020202072657475726E3B0A2020202020202020202020207D0A202020202020202020202020617065782E6576656E742E6743616E63656C466C6167203D20747275653B0A202020202020202020202020722E736179';
wwv_flow_imp.g_varchar2_table(1315) := '2874787428224255535922292C20227761726E22293B0A202020202020202020202020617065782E6D6573736167652E636C6561724572726F727328293B0A202020202020202020202020617065782E6D6573736167652E73686F774572726F7273285B';
wwv_flow_imp.g_varchar2_table(1316) := '7B20747970653A20226572726F72222C206C6F636174696F6E3A202270616765222C206D6573736167653A2028722E6366672E6C6162656C203F20722E6366672E6C6162656C202B20223A2022203A20222229202B2074787428224255535922292C2075';
wwv_flow_imp.g_varchar2_table(1317) := '6E736166653A2066616C7365207D5D293B0A20202020202020207D293B0A202020207D293B0A0A2020202072657475726E207B0A202020202020202076657273696F6E3A2056455253494F4E2C0A2020202020202020696E69743A20696E69742C0A2020';
wwv_flow_imp.g_varchar2_table(1318) := '202020202020707265736574733A20505245534554532C0A202020202020202074657874733A20544558542C0A20202020202020206669785765626D3A206669785765626D2C0A20202020202020206669784D70343A206669784D70342C0A2020202020';
wwv_flow_imp.g_varchar2_table(1319) := '2020206765743A2066756E6374696F6E20286974656D29207B0A2020202020202020202020207661722072203D20696E7374616E6365735B6974656D5D3B0A20202020202020202020202072657475726E2072202626207B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(1320) := '202020202073746172743A2066756E6374696F6E202829207B20722E737461727428293B207D2C0A2020202020202020202020202020202070617573653A2066756E6374696F6E202829207B20722E706175736528293B207D2C0A202020202020202020';
wwv_flow_imp.g_varchar2_table(1321) := '20202020202020726573756D653A2066756E6374696F6E202829207B20722E726573756D6528293B207D2C0A2020202020202020202020202020202073746F703A2066756E6374696F6E202829207B20722E73746F7028293B207D2C0A20202020202020';
wwv_flow_imp.g_varchar2_table(1322) := '202020202020202020636170747572653A2066756E6374696F6E202829207B20722E6361707475726528293B207D2C0A202020202020202020202020202020206B696E643A2066756E6374696F6E20286B29207B20696620286B29207B20722E7365744B';
wwv_flow_imp.g_varchar2_table(1323) := '696E64286B293B207D2072657475726E20722E6B696E643B207D2C0A202020202020202020202020202020207573653A2066756E6374696F6E202829207B20722E61636365707428293B207D2C0A20202020202020202020202020202020646973636172';
wwv_flow_imp.g_varchar2_table(1324) := '643A2066756E6374696F6E202829207B20722E646973636172642866616C7365293B207D2C0A2020202020202020202020202020202073746174653A2066756E6374696F6E202829207B2072657475726E20722E73746174653B207D2C0A202020202020';
wwv_flow_imp.g_varchar2_table(1325) := '202020202020202020206973427573793A2066756E6374696F6E202829207B2072657475726E20722E6275737928293B207D2C0A202020202020202020202020202020207265636F7264696E67733A2066756E6374696F6E202829207B0A202020202020';
wwv_flow_imp.g_varchar2_table(1326) := '202020202020202020202020202072657475726E20722E6974656D732E6D61702866756E6374696F6E20287829207B0A20202020202020202020202020202020202020202020202072657475726E207B207365713A20782E7365712C206E616D653A2078';
wwv_flow_imp.g_varchar2_table(1327) := '2E6E616D652C206D696D65547970653A20782E6D696D652C206B696E643A20782E6B696E642C2062797465733A20782E73697A652C207365636F6E64733A20782E6475726174696F6E2C0A20202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(1328) := '202020202020202077696474683A20782E77696474682C206865696768743A20782E6865696768742C207472616E7363726970743A20782E7472616E736372697074207D3B0A20202020202020202020202020202020202020207D293B0A202020202020';
wwv_flow_imp.g_varchar2_table(1329) := '202020202020202020207D0A2020202020202020202020207D3B0A20202020202020207D0A202020207D3B0A7D2928617065782E6A5175657279293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(12125902075788991)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_file_name=>'js/mediaPlus.js'
,p_mime_type=>'application/javascript'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A204D65646961506C757320666F72204F7261636C652041504558202D206974656D20706C75672D696E2076322E302E300A202A205265636F726420617564696F206F7220766964656F20616E642074616B652070686F746F7320696E2074';
wwv_flow_imp.g_varchar2_table(2) := '68652062726F77736572202D207265766965772C2063726F7020616E642061646A757374207468656D202D20616E64206B656570207468656D20696E20616E0A202A204150455820636F6C6C656374696F6E20756E74696C207468652070616765207361';
wwv_flow_imp.g_varchar2_table(3) := '766573207468656D2E0A202A202863292032303236204861736861616D2053686F756B6174202D204D4954204C6963656E73650A202A2F77696E646F772E6D65646961506C75733D66756E6374696F6E286E74297B2275736520737472696374223B7661';
wwv_flow_imp.g_varchar2_table(4) := '72204A743D22322E302E30222C78743D313537323836342C4E743D333265332C51743D332C54743D3265342C24743D372C74653D343039362C65653D5B22656E2D5553222C2261722D5341225D2C6D743D7B7D2C62743D7B534D414C4C3A7B617564696F';
wwv_flow_imp.g_varchar2_table(5) := '4B6270733A32342C766964656F4B6270733A3335302C766964656F4865696768743A3336302C6670733A31357D2C42414C414E4345443A7B617564696F4B6270733A34382C766964656F4B6270733A3930302C766964656F4865696768743A3438302C66';
wwv_flow_imp.g_varchar2_table(6) := '70733A32347D2C484947483A7B617564696F4B6270733A3132382C766964656F4B6270733A323530302C766964656F4865696768743A3732302C6670733A33307D7D2C41743D7B415544494F3A22417564696F222C564944454F3A22566964656F222C49';
wwv_flow_imp.g_varchar2_table(7) := '4D4147453A2250686F746F222C4B494E44533A225768617420746F20616464222C5245434F52443A225265636F7264222C54414B455F50484F544F3A2254616B652050686F746F222C434150545552453A2243617074757265222C5553455F50484F544F';
wwv_flow_imp.g_varchar2_table(8) := '3A225573652050686F746F222C524554414B453A2254616B6520416761696E222C50484F544F5F5449544C453A2243726F702C207475726E206F722061646A757374207468652070686F746F2C207468656E207573652069742E222C524F544154455F4C';
wwv_flow_imp.g_varchar2_table(9) := '4546543A22526F74617465204C656674222C524F544154455F52494748543A22526F74617465205269676874222C464C49503A22466C6970222C43524F503A2243726F70222C43524F505F465245453A2246726565222C43524F505F414C4C3A2257686F';
wwv_flow_imp.g_varchar2_table(10) := '6C652050686F746F222C41444A5553543A2241646A757374222C4252494748544E4553533A224272696768746E657373222C434F4E54524153543A22436F6E7472617374222C53415455524154494F4E3A22436F6C6F7572222C475241595343414C453A';
wwv_flow_imp.g_varchar2_table(11) := '22426C61636B20616E64205768697465222C445241573A2244726177222C554E444F3A22556E646F222C52455345543A225265736574222C53495A453A2253697A65222C53495A455F46554C4C3A2246756C6C2028253020707829222C53495A455F5058';
wwv_flow_imp.g_varchar2_table(12) := '3A222530207078222C50484F544F5F4D4554413A222530205C784437202531207078222C50484F544F5F53495A453A2261626F7574202530222C505245504152494E473A22507265706172696E67207468652070686F746F2E2E2E222C50484F544F5F46';
wwv_flow_imp.g_varchar2_table(13) := '41494C45443A22546869732070686F746F20636F756C64206E6F74206265206F70656E65642E202530222C50484F544F5F544F4F5F4C415247453A224576656E206D61646520736D616C6C65722C20746869732070686F746F206973206D6F7265207468';
wwv_flow_imp.g_varchar2_table(14) := '616E2025302E2043726F70206974206F722063686F6F7365206120736D616C6C65722073697A652E222C564945573A2256696577222C484944453A2248696465222C4F50454E5F43414D4552413A224F70656E2043616D657261222C53544152543A2253';
wwv_flow_imp.g_varchar2_table(15) := '74617274205265636F7264696E67222C50415553453A225061757365222C524553554D453A22526573756D65222C53544F503A2253746F70222C43414E43454C3A2243616E63656C222C434C4F53455F43414D4552413A22436C6F73652043616D657261';
wwv_flow_imp.g_varchar2_table(16) := '222C5357495443485F43414D4552413A225377697463682043616D657261222C43484F4F53455F46494C453A2243686F6F73652046696C65222C4445564943455F5245434F524445523A2255736520446576696365205265636F72646572222C5553453A';
wwv_flow_imp.g_varchar2_table(17) := '22557365205265636F7264696E67222C52455452593A2254727920416761696E222C414741494E3A225265636F726420416761696E222C444953434152443A2244697363617264222C444F574E4C4F41443A22446F776E6C6F6164222C504C41593A2250';
wwv_flow_imp.g_varchar2_table(18) := '6C6179222C484944455F504C415945523A224869646520506C61796572222C44454C4554453A2244656C657465222C52454144593A225265616479222C5245434F5244494E473A225265636F7264696E67222C5041555345443A22506175736564222C52';
wwv_flow_imp.g_varchar2_table(19) := '45564945573A22526576696577222C55504C4F4144494E473A22536176696E67222C5354415254494E473A225374617274696E67222C46494E495348494E473A2246696E697368696E67222C53415645443A225361766564222C50454E44494E473A2241';
wwv_flow_imp.g_varchar2_table(20) := '74746163686564222C5452414E5343524942494E475F5345525645523A225472616E7363726962696E67222C5245564945575F5449544C453A224C697374656E20746F206F7220776174636820796F7572207265636F7264696E67206265666F72652079';
wwv_flow_imp.g_varchar2_table(21) := '6F75207573652069742E222C55504C4F41445F50524F47524553533A22536176696E6720253025222C4C494D49545F48494E543A22557020746F202530222C4C494D49545F48494E545F54494D453A22557020746F202530206F72202531222C43415041';
wwv_flow_imp.g_varchar2_table(22) := '434954593A2261626F75742025302061742074686973207175616C697479222C4D455445523A2261626F7574202530206C656674205C784237202531206F66202532222C4F463A222530206F66202531222C5741524E5F53495A453A22416C6D6F737420';
wwv_flow_imp.g_varchar2_table(23) := '617420746865206C696D69743A202530206F6620253120757365642E205265636F7264696E672073746F7073206175746F6D61746963616C6C792061742025312E222C5741524E5F54494D453A22416C6D6F737420617420746865206C696D69743A2025';
wwv_flow_imp.g_varchar2_table(24) := '30206F662025312E205265636F7264696E672073746F7073206175746F6D61746963616C6C792061742025312E222C53544F505045445F53495A453A225265636F7264696E672073746F707065643A20746865206D6178696D756D2073697A65206F6620';
wwv_flow_imp.g_varchar2_table(25) := '25302077617320726561636865642E222C53544F505045445F54494D453A225265636F7264696E672073746F707065643A20746865206D6178696D756D206C656E677468206F662025302077617320726561636865642E222C4445564943455F454E4445';
wwv_flow_imp.g_varchar2_table(26) := '443A22546865206D6963726F70686F6E65206F722063616D657261207761732073746F707065642028666F72206578616D706C6520627920612063616C6C206F72207468652073637265656E206C6F636B696E67292E205768617420776173207265636F';
wwv_flow_imp.g_varchar2_table(27) := '7264656420736F20666172206973206B6570742E222C4D41585F434F554E543A22546865206D6178696D756D206F6620253020686173206265656E20726561636865642E2044656C657465206F6E6520746F2061646420616E6F746865722E222C4D4158';
wwv_flow_imp.g_varchar2_table(28) := '5F434F554E545F4F4E453A224F6E652068617320616C7265616479206265656E2061646465642E2044656C65746520697420746F2061646420616E6F746865722E222C46494C455F544F4F5F4C415247453A22546869732066696C652069732025302C20';
wwv_flow_imp.g_varchar2_table(29) := '6D6F7265207468616E20746865206D6178696D756D206F662025312E222C544F4F5F4C415247455F4B4545503A2254686973207265636F7264696E672063616D65206F75742061742025302C206D6F7265207468616E2074686520253120616C6C6F7765';
wwv_flow_imp.g_varchar2_table(30) := '642C20736F2069742063616E6E6F74206265207573656420686572652E20446F776E6C6F616420697420736F206974206973206E6F74206C6F73742C206F72207265636F726420612073686F72746572206F6E652E222C46494C455F57524F4E475F5459';
wwv_flow_imp.g_varchar2_table(31) := '50453A2243686F6F736520612066696C65206F6620616E20616C6C6F776564206B696E642E222C4E4F5F5045524D495353494F4E3A22416C6C6F772061636365737320746F20746865206D6963726F70686F6E65206F722063616D65726120696E20796F';
wwv_flow_imp.g_varchar2_table(32) := '75722062726F777365722073657474696E67732C207468656E2074727920616761696E2E222C4E4F5F4445564943453A224E6F206D6963726F70686F6E65206F722063616D6572612077617320666F756E642E222C4E4F545F535550504F525445443A22';
wwv_flow_imp.g_varchar2_table(33) := '5468652063616D65726120616E64206D6963726F70686F6E6520617265206E6F7420617661696C61626C6520686572653A2074686579206E6565642061207365637572652028687474707329207061676520616E6420612063757272656E742062726F77';
wwv_flow_imp.g_varchar2_table(34) := '7365722E222C425553593A2246696E6973682066697273743A20757365206F72206469736361726420746865207265636F7264696E67206F722070686F746F2E222C434F4E4649524D5F44454C4554453A2244656C65746520746869733F222C434F4E46';
wwv_flow_imp.g_varchar2_table(35) := '49524D5F444953434152443A224469736361726420746869733F222C55504C4F41445F4641494C45443A225468697320636F756C64206E6F742062652073617665642E202530204974206973207374696C6C2068657265202D2074727920616761696E2C';
wwv_flow_imp.g_varchar2_table(36) := '206F7220646F776E6C6F61642069742E222C4E4554574F524B3A2254686520636F6E6E656374696F6E20776173206C6F73742E222C53455353494F4E5F454E4445443A22596F75722073657373696F6E2068617320656E6465642C20736F207468697320';
wwv_flow_imp.g_varchar2_table(37) := '636F756C64206E6F742062652073617665642E20446F776E6C6F6164206974206E6F7720736F206974206973206E6F74206C6F73742C207468656E207369676E20696E20616761696E2E222C5245434F56455245443A22536F6D657468696E6720796F75';
wwv_flow_imp.g_varchar2_table(38) := '20686164206E6F7420757365642079657420776173207265636F76657265642E20557365206974206F7220646973636172642069742E222C504C41595F4641494C45443A22546865207265636F7264696E6720636F756C64206E6F7420626520706C6179';
wwv_flow_imp.g_varchar2_table(39) := '65642E202530222C5452414E5343524950543A225472616E736372697074222C5452414E5343524950545F4C414E47554147453A225472616E736372697074696F6E206C616E6775616765222C5452414E5343524950545F504C414345484F4C4445523A';
wwv_flow_imp.g_varchar2_table(40) := '224E6F7468696E6720776173207265636F676E69736564202D207479706520776861742077617320736169642C206F72206C6561766520697420656D7074792E222C5452414E5343524942494E473A224C697374656E696E672E2E2E222C5354545F554E';
wwv_flow_imp.g_varchar2_table(41) := '535550504F525445443A22546869732062726F777365722063616E6E6F74207472616E7363726962652E20596F752063616E2074797065207468652074657874206166746572207265636F7264696E672E222C5354545F4641494C45443A224C69766520';
wwv_flow_imp.g_varchar2_table(42) := '7472616E736372697074696F6E2073746F7070656420282530292E20596F752063616E2074797065206F7220636F7272656374207468652074657874206166746572207265636F7264696E672E222C4B4559533A2250203D207061757365202F20726573';
wwv_flow_imp.g_varchar2_table(43) := '756D652C2053203D2073746F70222C4E4F5F534F554E443A224E6F20736F756E64206973207265616368696E6720746865207265636F7264696E672E20436865636B20746865206D6963726F70686F6E65202D206966206865616470686F6E6573206F72';
wwv_flow_imp.g_varchar2_table(44) := '20416972506F64732061726520636F6E6E65637465642C2074727920616761696E20776974686F7574207468656D2E227D3B66756E6374696F6E206F2874297B76617220653D224D45444941504C55532E222B742C693D617065782E6C616E672E676574';
wwv_flow_imp.g_varchar2_table(45) := '4D6573736167652865292C6E3D41727261792E70726F746F747970652E736C6963652E63616C6C28617267756D656E74732C31293B72657475726E2821697C7C693D3D3D6529262628693D41745B745D7C7C74292C692E7265706C616365282F25285C64';
wwv_flow_imp.g_varchar2_table(46) := '292F672C66756E6374696F6E28732C72297B72657475726E206E5B725D213D3D766F696420303F6E5B725D3A737D297D66756E6374696F6E206628742C652C692C6E297B76617220733D646F63756D656E742E637265617465456C656D656E742874293B';
wwv_flow_imp.g_varchar2_table(47) := '72657475726E2065262628732E636C6173734E616D653D65292C6926264F626A6563742E6B6579732869292E666F72456163682866756E6374696F6E2872297B695B725D3D3D3D6E756C6C7C7C695B725D3D3D3D766F696420307C7C695B725D3D3D3D21';
wwv_flow_imp.g_varchar2_table(48) := '317C7C28723D3D3D2274657874223F732E74657874436F6E74656E743D695B725D3A732E73657441747472696275746528722C695B725D3D3D3D21303F22223A695B725D29297D292C286E7C7C5B5D292E666F72456163682866756E6374696F6E287229';
wwv_flow_imp.g_varchar2_table(49) := '7B722626732E617070656E644368696C642872297D292C737D66756E6374696F6E2043742874297B72657475726E206628227370616E222C22742D49636F6E20666120222B742C7B22617269612D68696464656E223A2274727565227D297D66756E6374';
wwv_flow_imp.g_varchar2_table(50) := '696F6E20447428742C652C69297B72657475726E20662822627574746F6E222C22742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D427574746F6E2D2D6E6F554920742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D';
wwv_flow_imp.g_varchar2_table(51) := '2D69636F6E20222B742C7B747970653A22627574746F6E222C7469746C653A692C22617269612D6C6162656C223A697D2C5B43742865295D297D7661722069653D7B226D706C75732D62746E2D2D726563223A22742D427574746F6E2D2D64616E676572';
wwv_flow_imp.g_varchar2_table(52) := '222C226D706C75732D62746E2D2D73746F70223A22742D427574746F6E2D2D64616E676572222C226D706C75732D62746E2D2D7072696D617279223A22742D427574746F6E2D2D686F74222C226D706C75732D62746E2D2D67686F7374223A22742D4275';
wwv_flow_imp.g_varchar2_table(53) := '74746F6E2D2D6E6F5549222C226D706C75732D62746E2D2D69636F6E223A22742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D2D69636F6E227D3B66756E6374696F6E20737428742C652C69297B766172206E3D742E71756572795365';
wwv_flow_imp.g_varchar2_table(54) := '6C6563746F7228222E6D706C75732D6922292C733D742E717565727953656C6563746F7228222E6D706C75732D62746E2D6C6162656C22293B6E2E636C6173734E616D653D226D706C75732D6920222B28652E696E6465784F66282266612D22293D3D3D';
wwv_flow_imp.g_varchar2_table(55) := '303F22666120222B653A226D706C75732D692D2D222B65292B28742E6D706C75735468656D653F2220742D49636F6E20742D49636F6E2D2D6C656674223A2222292C732E74657874436F6E74656E743D692C742E7469746C653D742E6D706C75734B6579';
wwv_flow_imp.g_varchar2_table(56) := '3F692B222028222B742E6D706C75734B65792B2229223A692C742E6D706C757349636F6E4F6E6C792626742E7365744174747269627574652822617269612D6C6162656C222C69297D66756E6374696F6E204728742C652C692C6E2C73297B7661722072';
wwv_flow_imp.g_varchar2_table(57) := '3D2828747C7C2222292B286E3F22206D706C75732D62746E2D2D69636F6E223A222229292E73706C697428222022292E66696C74657228426F6F6C65616E292C753D226D706C75732D62746E20222B722E6A6F696E28222022293B73262628753D226D70';
wwv_flow_imp.g_varchar2_table(58) := '6C75732D62746E2D2D7468656D6520742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D427574746F6E2D2D69636F6E4C65667420222B722E6D61702866756E6374696F6E2868297B72657475726E2069655B685D7C7C28682E696E6465';
wwv_flow_imp.g_varchar2_table(59) := '784F6628226D706C75732D62746E2D2D22293D3D3D303F22223A68297D292E6A6F696E2822202229293B766172206C3D662822627574746F6E222C752C7B747970653A22627574746F6E227D2C5B6628227370616E222C226D706C75732D69222C7B2261';
wwv_flow_imp.g_varchar2_table(60) := '7269612D68696464656E223A2274727565227D292C6628227370616E222C226D706C75732D62746E2D6C6162656C222B28733F2220742D427574746F6E2D6C6162656C223A222229295D293B72657475726E206C2E6D706C75735468656D653D2121732C';
wwv_flow_imp.g_varchar2_table(61) := '6C2E6D706C757349636F6E4F6E6C793D21216E2C7374286C2C652C69292C6C7D66756E6374696F6E205328742C65297B74262628742E68696464656E3D2165297D66756E6374696F6E20442874297B696628743C313032342972657475726E204D617468';
wwv_flow_imp.g_varchar2_table(62) := '2E726F756E642874292B222042223B696628743C313034383537362972657475726E204D6174682E726F756E6428742F31303234292B22204B42223B76617220653D742F313034383537363B72657475726E28653C31303F652E746F4669786564283129';
wwv_flow_imp.g_varchar2_table(63) := '3A4D6174682E726F756E64286529292B22204D42227D66756E6374696F6E20582874297B743D4D6174682E6D617828302C4D6174682E726F756E6428747C7C3029293B76617220653D4D6174682E666C6F6F7228742F33363030292C693D4D6174682E66';
wwv_flow_imp.g_varchar2_table(64) := '6C6F6F72287425333630302F3630292C6E3D742536303B72657475726E28653F652B223A222B537472696E672869292E706164537461727428322C223022293A69292B223A222B537472696E67286E292E706164537461727428322C223022297D66756E';
wwv_flow_imp.g_varchar2_table(65) := '6374696F6E206E652874297B72657475726E20743E3D333630303F28742F33363030292E746F46697865642831292E7265706C616365282F5C2E30242F2C2222292B222068223A743E3D3132303F4D6174682E726F756E6428742F3630292B22206D696E';
wwv_flow_imp.g_varchar2_table(66) := '223A582874297D66756E6374696F6E20736528297B76617220743D6E65772055696E74384172726179283136292C653D22223B72657475726E2077696E646F772E63727970746F2E67657452616E646F6D56616C7565732874292C742E666F7245616368';
wwv_flow_imp.g_varchar2_table(67) := '2866756E6374696F6E2869297B652B3D692E746F537472696E67283136292E706164537461727428322C223022297D292C657D66756E6374696F6E2067742874297B743D28747C7C2222292E73706C697428223B22295B305D3B76617220653D7B22696D';
wwv_flow_imp.g_varchar2_table(68) := '6167652F6A706567223A226A7067222C22696D6167652F706E67223A22706E67222C22696D6167652F77656270223A2277656270222C22696D6167652F676966223A22676966222C22696D6167652F68656963223A2268656963222C22617564696F2F77';
wwv_flow_imp.g_varchar2_table(69) := '65626D223A227765626D222C22766964656F2F7765626D223A227765626D222C22617564696F2F6D7034223A226D3461222C22766964656F2F6D7034223A226D7034222C22617564696F2F6F6767223A226F6767222C22617564696F2F6D706567223A22';
wwv_flow_imp.g_varchar2_table(70) := '6D7033222C22617564696F2F776176223A22776176222C22617564696F2F782D776176223A22776176222C22766964656F2F717569636B74696D65223A226D6F76222C22617564696F2F616163223A22616163222C22766964656F2F782D6D6174726F73';
wwv_flow_imp.g_varchar2_table(71) := '6B61223A226D6B76222C22617564696F2F782D6D3461223A226D3461222C22766964656F2F33677070223A22336770222C22617564696F2F33677070223A22336770227D3B72657475726E20655B745D7C7C28742E73706C697428222F22295B315D7C7C';
wwv_flow_imp.g_varchar2_table(72) := '2262696E22292E7265706C616365282F5B5E612D7A302D395D2F672C2222297D66756E6374696F6E20427428742C65297B6966282177696E646F772E4D656469615265636F726465727C7C214D656469615265636F726465722E69735479706553757070';
wwv_flow_imp.g_varchar2_table(73) := '6F727465642972657475726E22223B76617220693D7B617564696F3A7B5745424D3A5B22617564696F2F7765626D3B636F646563733D6F707573222C22617564696F2F7765626D225D2C4D50343A5B22617564696F2F6D70343B636F646563733D6D7034';
wwv_flow_imp.g_varchar2_table(74) := '612E34302E32222C22617564696F2F6D7034225D2C4F47473A5B22617564696F2F6F67673B636F646563733D6F707573225D7D2C766964656F3A7B5745424D3A5B22766964656F2F7765626D3B636F646563733D7670382C6F707573222C22766964656F';
wwv_flow_imp.g_varchar2_table(75) := '2F7765626D3B636F646563733D7670392C6F707573222C22766964656F2F7765626D225D2C4D50343A5B22766964656F2F6D70343B636F646563733D617663312E3432453031452C6D7034612E34302E32222C22766964656F2F6D70343B636F64656373';
wwv_flow_imp.g_varchar2_table(76) := '3D617663312C6D703461222C22766964656F2F6D7034225D7D7D2C6E3D653D3D3D225745424D223F5B225745424D222C224F4747222C224D5034225D3A5B224D5034222C225745424D222C224F4747225D2C733D22223B72657475726E206E2E736F6D65';
wwv_flow_imp.g_varchar2_table(77) := '2866756E6374696F6E2872297B72657475726E28695B745D5B725D7C7C5B5D292E736F6D652866756E6374696F6E2875297B72657475726E204D656469615265636F726465722E697354797065537570706F727465642875293F28733D752C2130293A21';
wwv_flow_imp.g_varchar2_table(78) := '317D297D292C737D66756E6374696F6E206B742874297B742E6164644576656E744C697374656E657228226C6F616465646D65746164617461222C66756E6374696F6E28297B696628742E6475726174696F6E3D3D3D312F307C7C69734E614E28742E64';
wwv_flow_imp.g_varchar2_table(79) := '75726174696F6E29297B76617220653D66756E6374696F6E28297B742E72656D6F76654576656E744C697374656E6572282274696D65757064617465222C65292C742E63757272656E7454696D653D307D3B742E6164644576656E744C697374656E6572';
wwv_flow_imp.g_varchar2_table(80) := '282274696D65757064617465222C65292C742E63757272656E7454696D653D31653130317D7D2C7B6F6E63653A21307D297D66756E6374696F6E2072652874297B72657475726E206E65772050726F6D6973652866756E6374696F6E28652C69297B7661';
wwv_flow_imp.g_varchar2_table(81) := '72206E3D6E65772046696C655265616465723B6E2E6F6E6C6F61643D66756E6374696F6E28297B6528537472696E67286E2E726573756C74292E73706C697428222C22295B315D7C7C2222297D2C6E2E6F6E6572726F723D66756E6374696F6E28297B69';
wwv_flow_imp.g_varchar2_table(82) := '286E2E6572726F72297D2C6E2E7265616441734461746155524C2874297D297D66756E6374696F6E2061652874297B72657475726E206E65772050726F6D6973652866756E6374696F6E2865297B76617220693D28742E747970657C7C2222292E696E64';
wwv_flow_imp.g_varchar2_table(83) := '65784F662822766964656F22293D3D3D303F22766964656F223A22617564696F222C6E3D646F63756D656E742E637265617465456C656D656E742869292C733D55524C2E6372656174654F626A65637455524C2874292C723D21312C753D66756E637469';
wwv_flow_imp.g_varchar2_table(84) := '6F6E286C297B727C7C28723D21302C55524C2E7265766F6B654F626A65637455524C2873292C6528697346696E697465286C293F6C3A3029297D3B6E2E7072656C6F61643D226D65746164617461222C6E2E6F6E6C6F616465646D657461646174613D66';
wwv_flow_imp.g_varchar2_table(85) := '756E6374696F6E28297B75286E2E6475726174696F6E297D2C6E2E6F6E6572726F723D66756E6374696F6E28297B752830297D2C73657454696D656F75742866756E6374696F6E28297B752830297D2C346533292C6E2E7372633D737D297D766172204F';
wwv_flow_imp.g_varchar2_table(86) := '743D66756E6374696F6E28297B76617220743D6E756C6C3B66756E6374696F6E206528297B72657475726E20747C7C28743D6E65772050726F6D6973652866756E6374696F6E286E2C73297B6966282177696E646F772E696E64657865644442297B7328';
wwv_flow_imp.g_varchar2_table(87) := '6E6577204572726F7228226E6F20496E646578656444422229293B72657475726E7D76617220723D696E646578656444422E6F70656E28226D65646961506C7573447261667473222C31293B722E6F6E757067726164656E65656465643D66756E637469';
wwv_flow_imp.g_varchar2_table(88) := '6F6E28297B722E726573756C742E6372656174654F626A65637453746F7265282264726166747322297D2C722E6F6E737563636573733D66756E6374696F6E28297B6E28722E726573756C74297D2C722E6F6E6572726F723D66756E6374696F6E28297B';
wwv_flow_imp.g_varchar2_table(89) := '7328722E6572726F72297D7D29292C747D66756E6374696F6E2069286E2C73297B72657475726E206528292E7468656E2866756E6374696F6E2872297B72657475726E206E65772050726F6D6973652866756E6374696F6E28752C6C297B76617220683D';
wwv_flow_imp.g_varchar2_table(90) := '722E7472616E73616374696F6E2822647261667473222C6E292C613D7328682E6F626A65637453746F726528226472616674732229293B682E6F6E636F6D706C6574653D66756E6374696F6E28297B7528612626612E726573756C74297D2C682E6F6E65';
wwv_flow_imp.g_varchar2_table(91) := '72726F723D682E6F6E61626F72743D66756E6374696F6E28297B6C28682E6572726F72297D7D297D292E63617463682866756E6374696F6E28297B72657475726E206E756C6C7D297D72657475726E7B6765743A66756E6374696F6E286E297B72657475';
wwv_flow_imp.g_varchar2_table(92) := '726E20692822726561646F6E6C79222C66756E6374696F6E2873297B72657475726E20732E676574286E297D297D2C7075743A66756E6374696F6E286E2C73297B72657475726E20692822726561647772697465222C66756E6374696F6E2872297B7265';
wwv_flow_imp.g_varchar2_table(93) := '7475726E20722E70757428732C6E297D297D2C64656C3A66756E6374696F6E286E297B72657475726E20692822726561647772697465222C66756E6374696F6E2873297B72657475726E20732E64656C657465286E297D297D7D7D28292C793D7B484541';
wwv_flow_imp.g_varchar2_table(94) := '4445523A3434303738363835312C5345474D454E543A3430383132353534332C5345454B484541443A3239303239383734302C5345454B3A31393839392C5345454B49443A32313431392C5345454B504F533A32313432302C494E464F3A333537313439';
wwv_flow_imp.g_varchar2_table(95) := '3033302C5343414C453A323830373732392C4455524154494F4E3A31373534352C545241434B533A3337343634383432372C545241434B3A3137342C545241434B4E4F3A3231352C545241434B545950453A3133312C434C55535445523A353234353331';
wwv_flow_imp.g_varchar2_table(96) := '3331372C54494D45434F44453A3233312C53494D504C45424C4F434B3A3136332C424C4F434B47524F55503A3136302C424C4F434B3A3136312C564F49443A3233362C435545533A3437353234393531352C435545504F494E543A3138372C4355455449';
wwv_flow_imp.g_varchar2_table(97) := '4D453A3137392C435545504F533A3138332C435545545241434B3A3234372C435545434C55535445523A3234317D2C6F653D5B792E5345454B484541442C792E494E464F2C792E545241434B532C792E434C55535445522C792E435545532C3330373534';
wwv_flow_imp.g_varchar2_table(98) := '343933352C3237323836393233322C3432333733323332395D3B66756E6374696F6E204228742C652C69297B666F7228766172206E3D745B655D2C733D312C723D3132383B733C3D38262621286E2672293B29732B2B2C723E3E3D313B696628733E3829';
wwv_flow_imp.g_varchar2_table(99) := '7468726F77206E6577204572726F7228226261642076696E7422293B666F722876617220753D693F6E3A6E26722D312C6C3D286E26722D31293D3D3D722D312C683D313B683C733B682B2B29753D752A3235362B745B652B685D2C6C3D6C2626745B652B';
wwv_flow_imp.g_varchar2_table(100) := '685D3D3D3D3235353B72657475726E7B763A752C6C656E3A732C756E6B6E6F776E3A216926266C7D7D66756E6374696F6E20767428742C652C69297B666F7228766172206E3D302C733D303B733C693B732B2B296E3D6E2A3235362B745B652B735D3B72';
wwv_flow_imp.g_varchar2_table(101) := '657475726E206E7D66756E6374696F6E2045742874297B666F722876617220653D5B5D3B743E303B29652E756E7368696674287426323535292C743D4D6174682E666C6F6F7228742F323536293B72657475726E206E65772055696E7438417272617928';
wwv_flow_imp.g_varchar2_table(102) := '65297D66756E6374696F6E204C742874297B76617220653D6E65772055696E743841727261792838293B655B305D3D313B666F722876617220693D373B693E3D313B692D2D29655B695D3D74253235362C743D4D6174682E666C6F6F7228742F32353629';
wwv_flow_imp.g_varchar2_table(103) := '3B72657475726E20657D66756E6374696F6E20497428742C65297B666F722876617220693D6E65772055696E743841727261792865292C6E3D652D313B6E3E3D303B6E2D2D29695B6E5D3D74253235362C743D4D6174682E666C6F6F7228742F32353629';
wwv_flow_imp.g_varchar2_table(104) := '3B72657475726E20697D66756E6374696F6E207128742C65297B76617220693D302C6E3D5B45742874292C4C742830295D3B72657475726E20652E666F72456163682866756E6374696F6E2873297B692B3D732E6C656E6774682C6E2E70757368287329';
wwv_flow_imp.g_varchar2_table(105) := '7D292C6E5B315D3D4C742869292C7B70617274733A6E2C73697A653A6E5B305D2E6C656E6774682B382B697D7D66756E6374696F6E20797428742C652C69297B72657475726E207128742C5B497428652C697C7C38295D297D66756E6374696F6E207474';
wwv_flow_imp.g_varchar2_table(106) := '2874297B76617220653D5B5D3B72657475726E20742E666F72456163682866756E6374696F6E2869297B41727261792E70726F746F747970652E707573682E6170706C7928652C692E7061727473297D292C657D66756E6374696F6E205F7428742C6529';
wwv_flow_imp.g_varchar2_table(107) := '7B72657475726E2F7765626D2F692E7465737428742E747970657C7C2222293F742E617272617942756666657228292E7468656E2866756E6374696F6E2869297B766172206E3D6E65772055696E743841727261792869292C733D302C722C752C6C2C68';
wwv_flow_imp.g_varchar2_table(108) := '3D5B5D2C613D3165362C643D6E756C6C2C703D5B5D2C673D5B5D2C453D312C523D303B696628723D42286E2C302C2130292C722E76213D3D792E4845414445522972657475726E20743B766172206B3D42286E2C722E6C656E293B733D722E6C656E2B6B';
wwv_flow_imp.g_varchar2_table(109) := '2E6C656E2B6B2E763B76617220483D6E2E737562617272617928302C73293B696628753D42286E2C732C2130292C752E76213D3D792E5345474D454E542972657475726E20743B766172204F3D42286E2C732B752E6C656E293B666F7228732B3D752E6C';
wwv_flow_imp.g_varchar2_table(110) := '656E2B4F2E6C656E2C6C3D4F2E756E6B6E6F776E3F6E2E6C656E6774683A4D6174682E6D696E286E2E6C656E6774682C732B4F2E76293B733C6C3B297B76617220493D42286E2C732C2130292C5F3D42286E2C732B492E6C656E292C503D732B492E6C65';
wwv_flow_imp.g_varchar2_table(111) := '6E2B5F2E6C656E2C563B696628492E763D3D3D792E434C5553544552297B666F7228766172207A3D7B74696D653A307D2C6D3D502C783D5F2E756E6B6E6F776E3F6C3A4D6174682E6D696E286C2C502B5F2E76292C623D21313B6D3C783B297B76617220';
wwv_flow_imp.g_varchar2_table(112) := '763D42286E2C6D2C2130293B6966286F652E696E6465784F6628762E76293E3D3029627265616B3B76617220413D42286E2C6D2B762E6C656E292C543D6D2B762E6C656E2B412E6C656E3B696628412E756E6B6E6F776E7C7C542B412E763E6E2E6C656E';
wwv_flow_imp.g_varchar2_table(113) := '677468297B623D21303B627265616B7D762E763D3D3D792E54494D45434F44452626287A2E74696D653D7674286E2C542C412E7629293B766172204C3D762E763D3D3D792E53494D504C45424C4F434B3F543A762E763D3D3D792E424C4F434B47524F55';
wwv_flow_imp.g_varchar2_table(114) := '5026266E5B545D3D3D3D792E424C4F434B3F542B312B42286E2C542B31292E6C656E3A2D313B6966284C3E3D30297B766172204D3D42286E2C4C292C553D6E5B4C2B4D2E6C656E5D3C3C387C6E5B4C2B4D2E6C656E2B315D3B553E333237363726262855';
wwv_flow_imp.g_varchar2_table(115) := '2D3D3635353336292C523D4D6174682E6D617828522C7A2E74696D652B55292C7A2E6B65793D3D3D766F6964203026264D2E763D3D3D452626287A2E6B65793D762E76213D3D792E53494D504C45424C4F434B7C7C286E5B4C2B4D2E6C656E2B325D2631';
wwv_flow_imp.g_varchar2_table(116) := '323829213D3D30297D6D3D542B412E767D6966286D3E502626287A2E626F64793D6E2E737562617272617928502C6D292C672E70757368287A29292C627C7C6D3D3D3D5029627265616B3B733D6D3B636F6E74696E75657D6966285F2E756E6B6E6F776E';
wwv_flow_imp.g_varchar2_table(117) := '2972657475726E20743B696628563D502B5F2E762C492E763D3D3D792E494E464F29666F722876617220573D503B573C563B297B766172206A3D42286E2C572C2130292C5A3D42286E2C572B6A2E6C656E292C65743D572B6A2E6C656E2B5A2E6C656E3B';
wwv_flow_imp.g_varchar2_table(118) := '6A2E763D3D3D792E5343414C45262628613D7674286E2C65742C5A2E7629292C6A2E76213D3D792E4455524154494F4E2626682E70757368286E2E737562617272617928572C65742B5A2E7629292C573D65742B5A2E767D656C736520696628492E763D';
wwv_flow_imp.g_varchar2_table(119) := '3D3D792E545241434B53297B643D6E2E737562617272617928732C56293B666F722876617220773D502C463D302C70743D303B773C563B297B76617220593D42286E2C772C2130292C61743D42286E2C772B592E6C656E292C4E3D772B592E6C656E2B61';
wwv_flow_imp.g_varchar2_table(120) := '742E6C656E3B696628592E763D3D3D792E545241434B297B666F7228766172206F743D302C64743D302C4A3D4E3B4A3C4E2B61742E763B297B7661722075743D42286E2C4A2C2130292C69743D42286E2C4A2B75742E6C656E292C6C743D4A2B75742E6C';
wwv_flow_imp.g_varchar2_table(121) := '656E2B69742E6C656E3B75742E763D3D3D792E545241434B4E4F2626286F743D7674286E2C6C742C69742E7629292C75742E763D3D3D792E545241434B5459504526262864743D7674286E2C6C742C69742E7629292C4A3D6C742B69742E767D463D467C';
wwv_flow_imp.g_varchar2_table(122) := '7C6F742C64743D3D3D31262621707426262870743D6F74297D773D4E2B61742E767D453D70747C7C467C7C317D656C736520492E76213D3D792E5345454B484541442626492E76213D3D792E564F49442626492E76213D3D792E435545532626702E7075';
wwv_flow_imp.g_varchar2_table(123) := '7368286E2E737562617272617928732C5629293B733D567D69662821647C7C21672E6C656E6774682972657475726E20743B7661722052743D523E303F522A612F3165363A652C47743D6E6577204461746156696577286E657720417272617942756666';
wwv_flow_imp.g_varchar2_table(124) := '6572283829293B47742E736574466C6F6174363428302C52742A3165362F61293B7661722056743D7128792E494E464F2C682E636F6E636174285B457428792E4455524154494F4E292C6E65772055696E74384172726179285B3133365D292C6E657720';
wwv_flow_imp.g_varchar2_table(125) := '55696E743841727261792847742E627566666572295D29292C7A743D672E6D61702866756E6374696F6E2851297B72657475726E207128792E434C55535445522C5B512E626F64795D297D292C67653D702E7265647563652866756E6374696F6E28512C';
wwv_flow_imp.g_varchar2_table(126) := '24297B72657475726E20512B242E6C656E6774687D2C30292C63743D66756E6374696F6E28512C24297B72657475726E207128792E5345454B2C7474285B7128792E5345454B49442C5B45742851295D292C797428792E5345454B504F532C24295D2929';
wwv_flow_imp.g_varchar2_table(127) := '7D2C76653D7128792E5345454B484541442C7474285B637428792E494E464F2C30292C637428792E545241434B532C30292C637428792E435545532C30295D29292E73697A652C71743D76652C59743D71742B56742E73697A652C55743D59742B642E6C';
wwv_flow_imp.g_varchar2_table(128) := '656E6774682B67652C58743D5B5D3B7A742E666F72456163682866756E6374696F6E28512C24297B28243D3D3D307C7C675B245D2E6B657929262658742E70757368287128792E435545504F494E542C7474285B797428792E43554554494D452C675B24';
wwv_flow_imp.g_varchar2_table(129) := '5D2E74696D65292C7128792E435545504F532C7474285B797428792E435545545241434B2C452C31292C797428792E435545434C55535445522C5574295D29295D2929292C55742B3D512E73697A657D293B7661722045653D7128792E435545532C7474';
wwv_flow_imp.g_varchar2_table(130) := '28587429292C79653D7128792E5345454B484541442C7474285B637428792E494E464F2C7174292C637428792E545241434B532C5974292C637428792E435545532C5574295D29292C5A743D7474285B79652C56745D292E636F6E636174285B645D2C70';
wwv_flow_imp.g_varchar2_table(131) := '2C7474287A74292C45652E7061727473292C77653D5A742E7265647563652866756E6374696F6E28512C24297B72657475726E20512B242E6C656E6774687D2C30293B72657475726E206E657720426C6F62285B482C457428792E5345474D454E54292C';
wwv_flow_imp.g_varchar2_table(132) := '4C74287765295D2E636F6E636174285A74292C7B747970653A742E747970657D297D292E63617463682866756E6374696F6E2869297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28224D65646961506C7573';
wwv_flow_imp.g_varchar2_table(133) := '3A205765624D206C656674206173207265636F72646564222C69292C747D293A50726F6D6973652E7265736F6C76652874297D66756E6374696F6E204328742C65297B72657475726E20745B655D2A31363737373231362B28745B652B315D3C3C313629';
wwv_flow_imp.g_varchar2_table(134) := '2B28745B652B325D3C3C38292B745B652B335D7D66756E6374696F6E20467428742C652C69297B666F7228766172206E3D5B5D2C733D653B732B383C3D693B297B76617220723D4328742C73292C753D732B383B696628723D3D3D313F28723D4328742C';
wwv_flow_imp.g_varchar2_table(135) := '732B38292A343239343936373239362B4328742C732B3132292C753D732B3136293A723D3D3D30262628723D692D73292C723C387C7C732B723E69297468726F77206E6577204572726F72282262616420626F7822293B6E2E70757368287B747970653A';
wwv_flow_imp.g_varchar2_table(136) := '537472696E672E66726F6D43686172436F646528745B732B345D2C745B732B355D2C745B732B365D2C745B732B375D292C73746172743A732C646174613A752C656E643A732B727D292C732B3D727D72657475726E206E7D66756E6374696F6E204B2874';
wwv_flow_imp.g_varchar2_table(137) := '2C652C69297B72657475726E20467428742C652E646174612C652E656E64292E66696C7465722866756E6374696F6E286E297B72657475726E21697C7C6E2E747970653D3D3D697D297D66756E6374696F6E20727428742C65297B76617220693D382C6E';
wwv_flow_imp.g_varchar2_table(138) := '2C733D383B652E666F72456163682866756E6374696F6E2875297B692B3D752E6C656E6774687D292C6E3D6E65772055696E743841727261792869292C6E2E73657428497428692C34292C30293B666F722876617220723D303B723C343B722B2B296E5B';
wwv_flow_imp.g_varchar2_table(139) := '342B725D3D742E63686172436F646541742872293B72657475726E20652E666F72456163682866756E6374696F6E2875297B6E2E73657428752C73292C732B3D752E6C656E6774687D292C6E7D66756E6374696F6E20687428742C652C69297B76617220';
wwv_flow_imp.g_varchar2_table(140) := '6E3D6E65772055696E7438417272617928342B692E6C656E6774682A34292C733D6E6577204461746156696577286E2E627566666572293B72657475726E206E5B305D3D652C692E666F72456163682866756E6374696F6E28722C75297B732E73657455';
wwv_flow_imp.g_varchar2_table(141) := '696E74333228342B752A342C723E3E3E30297D292C727428742C5B6E5D297D66756E6374696F6E204B7428742C65297B72657475726E20742E666F72456163682866756E6374696F6E2869297B652E6C656E6774682626655B652E6C656E6774682D315D';
wwv_flow_imp.g_varchar2_table(142) := '3D3D3D693F655B652E6C656E6774682D325D2B2B3A652E7075736828312C69297D292C657D66756E6374696F6E2048742874297B72657475726E2F6D70347C6D34617C717569636B74696D652F692E7465737428742E747970657C7C2222293F742E6172';
wwv_flow_imp.g_varchar2_table(143) := '72617942756666657228292E7468656E2866756E6374696F6E2865297B76617220693D6E65772055696E743841727261792865292C6E3D6E65772044617461566965772865292C733D467428692C302C692E6C656E677468292C722C752C6C3D7B7D2C68';
wwv_flow_imp.g_varchar2_table(144) := '3D5B5D2C613D7B7D2C643D5B5D3B696628723D732E66696C7465722866756E6374696F6E286D297B72657475726E206D2E747970653D3D3D226D6F6F76227D295B305D2C21727C7C21732E736F6D652866756E6374696F6E286D297B72657475726E206D';
wwv_flow_imp.g_varchar2_table(145) := '2E747970653D3D3D226D6F6F66227D297C7C284B28692C72292E666F72456163682866756E6374696F6E286D297B6966286D2E747970653D3D3D226D7668642229753D6D3B656C7365206966286D2E747970653D3D3D227472616B22297B76617220783D';
wwv_flow_imp.g_varchar2_table(146) := '4B28692C6D2C22746B686422295B305D2C623D4B28692C6D2C226D64696122295B305D2C763D4B28692C622C226D64686422295B305D2C413D4B28692C622C2268646C7222295B305D2C543D4B28692C622C226D696E6622295B305D2C4C3D4B28692C54';
wwv_flow_imp.g_varchar2_table(147) := '2C227374626C22295B305D2C4D3D4328692C782E646174612B28695B782E646174615D3D3D3D313F32303A313229293B6C5B4D5D3D7B7472616B3A6D2C746B68643A782C6D6469613A622C6D6468643A762C6D696E663A542C737473643A4B28692C4C2C';
wwv_flow_imp.g_varchar2_table(148) := '227374736422295B305D2C7363616C653A4328692C762E646174612B28695B762E646174615D3D3D3D313F32303A313229292C766964656F3A4126264328692C412E646174612B38293D3D3D313938363631383436392C647572733A5B5D2C73697A6573';
wwv_flow_imp.g_varchar2_table(149) := '3A5B5D2C63746F733A5B5D2C73796E633A5B5D2C6368756E6B733A5B5D7D2C682E70757368284D297D656C7365206D2E747970653D3D3D226D766578223F4B28692C6D2C227472657822292E666F72456163682866756E6374696F6E2855297B615B4328';
wwv_flow_imp.g_varchar2_table(150) := '692C552E646174612B34295D3D7B6475723A4328692C552E646174612B3132292C73697A653A4328692C552E646174612B3136292C666C6167733A4328692C552E646174612B3230297D7D293A642E7075736828692E7375626172726179286D2E737461';
wwv_flow_imp.g_varchar2_table(151) := '72742C6D2E656E6429297D292C21757C7C21682E6C656E677468292972657475726E20743B732E666F72456163682866756E6374696F6E286D297B6D2E747970653D3D3D226D6F6F662226264B28692C6D2C227472616622292E666F7245616368286675';
wwv_flow_imp.g_varchar2_table(152) := '6E6374696F6E2878297B76617220623D4B28692C78292C763D622E66696C7465722866756E6374696F6E2846297B72657475726E20462E747970653D3D3D2274666864227D295B305D2C413D4328692C762E64617461292631363737373231352C543D76';
wwv_flow_imp.g_varchar2_table(153) := '2E646174612B382C4C3D4328692C762E646174612B34292C4D3D6C5B4C5D2C553D615B4C5D7C7C7B7D2C573D6D2E73746172742C6A3D552E6475727C7C302C5A3D552E73697A657C7C302C65743D552E666C6167737C7C302C773B412631262628573D43';
wwv_flow_imp.g_varchar2_table(154) := '28692C54292A343239343936373239362B4328692C542B34292C542B3D38292C412632262628542B3D34292C4126382626286A3D4328692C54292C542B3D34292C412631362626285A3D4328692C54292C542B3D34292C4126333226262865743D432869';
wwv_flow_imp.g_varchar2_table(155) := '2C5429292C4D262628773D572C622E666F72456163682866756E6374696F6E2846297B696628462E747970653D3D3D227472756E22297B7661722070743D695B462E646174615D2C593D4328692C462E64617461292631363737373231352C61743D4328';
wwv_flow_imp.g_varchar2_table(156) := '692C462E646174612B34292C4E3D462E646174612B382C6F743D6E756C6C2C64743B592631262628773D572B6E2E676574496E743332284E292C4E2B3D34292C5926342626286F743D4328692C4E292C4E2B3D34292C64743D773B666F7228766172204A';
wwv_flow_imp.g_varchar2_table(157) := '3D303B4A3C61743B4A2B2B297B7661722075743D6A2C69743D5A2C6C743D65742C52743D303B592632353626262875743D4328692C4E292C4E2B3D34292C592635313226262869743D4328692C4E292C4E2B3D34292C5926313032342626286C743D4328';
wwv_flow_imp.g_varchar2_table(158) := '692C4E292C4E2B3D34292C59263230343826262852743D70743F6E2E676574496E743332284E293A4328692C4E292C4E2B3D34292C4A3D3D3D3026266F74213D3D6E756C6C2626286C743D6F74292C4D2E647572732E70757368287574292C4D2E73697A';
wwv_flow_imp.g_varchar2_table(159) := '65732E70757368286974292C4D2E63746F732E70757368285274292C4D2E73796E632E707573682821286C7426363535333629292C772B3D69747D696628773E692E6C656E677468297468726F77206E6577204572726F7228226375742D6F6666207361';
wwv_flow_imp.g_varchar2_table(160) := '6D706C65206461746122293B617426264D2E6368756E6B732E70757368287B66726F6D3A64742C73697A653A772D64742C636F756E743A61747D297D7D29297D297D293B76617220703D5B5D2C673D303B696628682E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(161) := '6F6E286D297B703D702E636F6E636174286C5B6D5D2E6368756E6B73297D292C21702E6C656E6774687C7C28702E736F72742866756E6374696F6E286D2C78297B72657475726E206D2E66726F6D2D782E66726F6D7D292E666F72456163682866756E63';
wwv_flow_imp.g_varchar2_table(162) := '74696F6E286D297B6D2E61743D672C672B3D6D2E73697A657D292C673E346539292972657475726E20743B76617220453D4328692C752E646174612B28695B752E646174615D3D3D3D313F32303A313229292C523D303B682E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(163) := '6374696F6E286D297B76617220783D6C5B6D5D3B782E6475723D782E647572732E7265647563652866756E6374696F6E28622C76297B72657475726E20622B767D2C30292C782E6D4475723D4D6174682E726F756E6428782E6475722A452F782E736361';
wwv_flow_imp.g_varchar2_table(164) := '6C65292C523D4D6174682E6D617828522C782E6D447572297D293B766172206B3D66756E6374696F6E286D2C782C622C76297B76617220413D692E736C696365286D2E73746172742C6D2E656E64292C543D6E657720446174615669657728412E627566';
wwv_flow_imp.g_varchar2_table(165) := '666572292C4C3D6D2E646174612D6D2E73746172743B72657475726E20415B4C5D3D3D3D313F28542E73657455696E743332284C2B622C4D6174682E666C6F6F7228762F3432393439363732393629292C542E73657455696E743332284C2B622B342C76';
wwv_flow_imp.g_varchar2_table(166) := '3E3E3E3029293A542E73657455696E743332284C2B782C763E3E3E30292C417D2C483D66756E6374696F6E286D297B72657475726E20692E7375626172726179286D2E73746172742C6D2E656E64297D2C4F3D66756E6374696F6E286D2C78297B766172';
wwv_flow_imp.g_varchar2_table(167) := '20623D6B286D2C32302C32382C782E6D447572292C763D6D2E646174612D6D2E73746172742C413D6E657720446174615669657728622E627566666572293B72657475726E20625B762B335D3D625B762B335D7C372C782E766964656F7C7C412E736574';
wwv_flow_imp.g_varchar2_table(168) := '55696E74313628762B28625B765D3D3D3D313F34383A3336292C323536292C627D2C493D66756E6374696F6E286D297B76617220783D682E6D61702866756E6374696F6E2862297B76617220763D6C5B625D2C413D4B7428762E647572732C5B5D292C54';
wwv_flow_imp.g_varchar2_table(169) := '3D4B7428762E63746F732C5B5D292C4C3D5B5D2C4D3D5B5D2C553D5B5D2C573D2D312C6A3D5B4828762E73747364292C6874282273747473222C302C5B412E6C656E6774682F325D2E636F6E636174284129295D3B762E63746F732E736F6D652866756E';
wwv_flow_imp.g_varchar2_table(170) := '6374696F6E2877297B72657475726E2077213D3D307D2926266A2E70757368286874282263747473222C762E63746F732E736F6D652866756E6374696F6E2877297B72657475726E20773C307D293F313A302C5B542E6C656E6774682F325D2E636F6E63';
wwv_flow_imp.g_varchar2_table(171) := '617428542929292C762E73796E632E666F72456163682866756E6374696F6E28772C46297B772626552E7075736828462B31297D292C762E766964656F2626552E6C656E6774683C762E73796E632E6C656E67746826266A2E7075736828687428227374';
wwv_flow_imp.g_varchar2_table(172) := '7373222C302C5B552E6C656E6774685D2E636F6E63617428552929292C6A2E7075736828687428227374737A222C302C5B302C762E73697A65732E6C656E6774685D2E636F6E63617428762E73697A65732929292C762E6368756E6B732E666F72456163';
wwv_flow_imp.g_varchar2_table(173) := '682866756E6374696F6E28772C46297B772E636F756E74213D3D572626284C2E7075736828462B312C772E636F756E742C31292C573D772E636F756E74292C4D2E70757368286D2B772E6174297D292C6A2E70757368286874282273747363222C302C5B';
wwv_flow_imp.g_varchar2_table(174) := '4C2E6C656E6774682F335D2E636F6E636174284C29292C687428227374636F222C302C5B4D2E6C656E6774685D2E636F6E636174284D2929293B766172205A3D727428226D696E66222C4B28692C762E6D696E66292E66696C7465722866756E6374696F';
wwv_flow_imp.g_varchar2_table(175) := '6E2877297B72657475726E20772E74797065213D3D227374626C227D292E6D61702848292E636F6E636174285B727428227374626C222C6A295D29292C65743D727428226D646961222C4B28692C762E6D646961292E6D61702866756E6374696F6E2877';
wwv_flow_imp.g_varchar2_table(176) := '297B72657475726E20772E747970653D3D3D226D646864223F6B28772C31362C32342C762E647572293A772E747970653D3D3D226D696E66223F5A3A482877297D29293B72657475726E20727428227472616B222C4B28692C762E7472616B292E66696C';
wwv_flow_imp.g_varchar2_table(177) := '7465722866756E6374696F6E2877297B72657475726E20772E74797065213D3D2265647473227D292E6D61702866756E6374696F6E2877297B72657475726E20772E747970653D3D3D22746B6864223F4F28772C76293A772E747970653D3D3D226D6469';
wwv_flow_imp.g_varchar2_table(178) := '61223F65743A482877297D29297D293B72657475726E20727428226D6F6F76222C5B6B28752C31362C32342C52295D2E636F6E63617428782C6429297D2C5F3D7274282266747970222C5B2269736F6D222C225C305C30025C30222C2269736F6D222C22';
wwv_flow_imp.g_varchar2_table(179) := '69736F32222C2261766331222C226D703431225D2E6D61702866756E6374696F6E286D297B72657475726E206E65772055696E74384172726179286D2E73706C6974282222292E6D61702866756E6374696F6E2878297B72657475726E20782E63686172';
wwv_flow_imp.g_varchar2_table(180) := '436F646541742830297D29297D29292C503D492830292E6C656E6774682C563D49285F2E6C656E6774682B502B38292C7A3D5B5F2C562C497428672B382C34292C6E65772055696E74384172726179285B3130392C3130302C39372C3131365D295D3B72';
wwv_flow_imp.g_varchar2_table(181) := '657475726E20702E666F72456163682866756E6374696F6E286D297B7A2E7075736828692E7375626172726179286D2E66726F6D2C6D2E66726F6D2B6D2E73697A6529297D292C6E657720426C6F62287A2C7B747970653A742E747970657D297D292E63';
wwv_flow_imp.g_varchar2_table(182) := '617463682866756E6374696F6E2865297B72657475726E2077696E646F772E636F6E736F6C652626636F6E736F6C652E7761726E28224D65646961506C75733A204D5034206C656674206173207265636F72646564222C65292C747D293A50726F6D6973';
wwv_flow_imp.g_varchar2_table(183) := '652E7265736F6C76652874297D66756E6374696F6E20756528742C65297B72657475726E2F7765626D2F692E7465737428742E747970657C7C2222293F5F7428742C65293A48742874297D66756E6374696F6E2066742874297B7472797B6E6176696761';
wwv_flow_imp.g_varchar2_table(184) := '746F722E617564696F53657373696F6E26266E6176696761746F722E617564696F53657373696F6E2E74797065213D3D742626286E6176696761746F722E617564696F53657373696F6E2E747970653D74297D63617463687B7D7D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(185) := '6C652874297B76617220653D537472696E6728747C7C2222292E73706C697428222F22295B305D2E746F55707065724361736528293B72657475726E20653D3D3D22564944454F227C7C653D3D3D22494D414745223F653A22415544494F227D76617220';
wwv_flow_imp.g_varchar2_table(186) := '4D743D66756E6374696F6E28297B7472797B72657475726E20747970656F6620646F63756D656E742E637265617465456C656D656E74282263616E76617322292E676574436F6E746578742822326422292E66696C7465723D3D22737472696E67227D63';
wwv_flow_imp.g_varchar2_table(187) := '617463687B72657475726E21317D7D28293B66756E6374696F6E20777428742C65297B76617220693D646F63756D656E742E637265617465456C656D656E74282263616E76617322293B72657475726E20692E77696474683D4D6174682E6D617828312C';
wwv_flow_imp.g_varchar2_table(188) := '4D6174682E726F756E64287429292C692E6865696768743D4D6174682E6D617828312C4D6174682E726F756E64286529292C697D66756E6374696F6E20577428742C652C69297B72657475726E206E65772050726F6D6973652866756E6374696F6E286E';
wwv_flow_imp.g_varchar2_table(189) := '2C73297B742E746F426C6F622866756E6374696F6E2872297B723F6E2872293A73286E6577204572726F722822656E636F64652229297D2C652C69297D297D66756E6374696F6E2068652874297B72657475726E206E65772050726F6D6973652866756E';
wwv_flow_imp.g_varchar2_table(190) := '6374696F6E28652C69297B766172206E3D55524C2E6372656174654F626A65637455524C2874292C733D6E657720496D6167653B732E6F6E6C6F61643D66756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C286E293B7661722072';
wwv_flow_imp.g_varchar2_table(191) := '3D732E6E61747572616C57696474682C753D732E6E61747572616C4865696768742C6C3D4D6174682E6D696E28312C74652F4D6174682E6D617828722C7529293B69662821727C7C2175297B69286E6577204572726F722822656D7074792229293B7265';
wwv_flow_imp.g_varchar2_table(192) := '7475726E7D76617220683D777428722A6C2C752A6C292C613D682E676574436F6E746578742822326422293B612E696D616765536D6F6F7468696E675175616C6974793D2268696768222C612E64726177496D61676528732C302C302C682E7769647468';
wwv_flow_imp.g_varchar2_table(193) := '2C682E686569676874292C652868297D2C732E6F6E6572726F723D66756E6374696F6E28297B55524C2E7265766F6B654F626A65637455524C286E292C69286E6577204572726F7228742E747970657C7C222229297D2C732E7372633D6E7D297D66756E';
wwv_flow_imp.g_varchar2_table(194) := '6374696F6E2064652874297B76617220653D5B5D3B72657475726E20742E61646A2E62213D3D3130302626652E7075736828226272696768746E65737328222B742E61646A2E622B22252922292C742E61646A2E63213D3D3130302626652E7075736828';
wwv_flow_imp.g_varchar2_table(195) := '22636F6E747261737428222B742E61646A2E632B22252922292C742E61646A2E73213D3D313030262621742E677261792626652E707573682822736174757261746528222B742E61646A2E732B22252922292C742E677261792626652E70757368282267';
wwv_flow_imp.g_varchar2_table(196) := '7261797363616C6528312922292C652E6A6F696E28222022297D66756E6374696F6E20636528742C652C692C6E297B666F722876617220733D742E676574496D6167654461746128302C302C652C69292C723D732E646174612C753D6E2E61646A2E622F';
wwv_flow_imp.g_varchar2_table(197) := '3130302C6C3D6E2E61646A2E632F3130302C683D6E2E677261793F303A6E2E61646A2E732F3130302C613D303B613C722E6C656E6774683B612B3D34297B76617220643D28725B615D2A752D313238292A6C2B3132382C703D28725B612B315D2A752D31';
wwv_flow_imp.g_varchar2_table(198) := '3238292A6C2B3132382C673D28725B612B325D2A752D313238292A6C2B3132382C453D2E323132362A642B2E373135322A702B2E303732322A673B725B615D3D452B28642D45292A682C725B612B315D3D452B28702D45292A682C725B612B325D3D452B';
wwv_flow_imp.g_varchar2_table(199) := '28672D45292A687D742E707574496D6167654461746128732C302C30297D66756E6374696F6E20666528742C652C692C6E297B652E666F72456163682866756E6374696F6E2873297B696628732E7074732E6C656E677468297B742E7361766528292C74';
wwv_flow_imp.g_varchar2_table(200) := '2E7374726F6B655374796C653D732E636F6C6F75722C742E6C696E6557696474683D4D6174682E6D617828312C732E772A4D6174682E6D617828692C6E29292C742E6C696E654361703D742E6C696E654A6F696E3D22726F756E64222C742E626567696E';
wwv_flow_imp.g_varchar2_table(201) := '5061746828292C742E6D6F7665546F28732E7074735B305D5B305D2A692C732E7074735B305D5B315D2A6E293B666F722876617220723D313B723C732E7074732E6C656E6774683B722B2B29742E6C696E65546F28732E7074735B725D5B305D2A692C73';
wwv_flow_imp.g_varchar2_table(202) := '2E7074735B725D5B315D2A6E293B732E7074732E6C656E6774683D3D3D312626742E6C696E65546F28732E7074735B305D5B305D2A692B2E312C732E7074735B305D5B315D2A6E292C742E7374726F6B6528292C742E726573746F726528297D7D297D66';
wwv_flow_imp.g_varchar2_table(203) := '756E6374696F6E206A7428742C652C69297B766172206E3D742E7372632E77696474682C733D742E7372632E6865696768742C723D742E726F7425313830213D3D302C753D723F733A6E2C6C3D723F6E3A732C683D693F742E63726F703A7B783A302C79';
wwv_flow_imp.g_varchar2_table(204) := '3A302C773A312C683A317D2C613D4D6174682E6D696E28312C652F4D6174682E6D617828682E772A752C682E682A6C29292C643D7774286E2A612C732A61292C703D642E676574436F6E746578742822326422292C673D64652874293B702E696D616765';
wwv_flow_imp.g_varchar2_table(205) := '536D6F6F7468696E675175616C6974793D2268696768222C6726264D74262628702E66696C7465723D67292C702E64726177496D61676528742E7372632C302C302C642E77696474682C642E686569676874292C6726264D74262628702E66696C746572';
wwv_flow_imp.g_varchar2_table(206) := '3D226E6F6E6522292C672626214D742626636528702C642E77696474682C642E6865696768742C74292C666528702C742E7374726F6B65732C642E77696474682C642E686569676874293B76617220453D777428682E772A752A612C682E682A6C2A6129';
wwv_flow_imp.g_varchar2_table(207) := '2C523D452E676574436F6E746578742822326422293B72657475726E20522E696D616765536D6F6F7468696E675175616C6974793D2268696768222C522E7472616E736C617465282D682E782A752A612B752A612F322C2D682E792A6C2A612B6C2A612F';
wwv_flow_imp.g_varchar2_table(208) := '32292C522E726F7461746528742E726F742A4D6174682E50492F313830292C522E7363616C6528742E666C69703F2D313A312C31292C522E64726177496D61676528642C2D642E77696474682F322C2D642E6865696768742F32292C457D66756E637469';
wwv_flow_imp.g_varchar2_table(209) := '6F6E20706528742C652C692C6E2C73297B76617220723D652C753D6E2C6C3D302C683D66756E6374696F6E28297B76617220613D6A7428742C722C2130293B72657475726E20577428612C692C75292E7468656E2866756E6374696F6E2864297B726574';
wwv_flow_imp.g_varchar2_table(210) := '75726E20693D3D3D22696D6167652F77656270222626642E74797065213D3D693F28693D22696D6167652F6A706567222C682829293A642E73697A653C3D737C7C2B2B6C3E31323F7B626C6F623A642C77696474683A612E77696474682C686569676874';
wwv_flow_imp.g_varchar2_table(211) := '3A612E6865696768742C666974733A642E73697A653C3D737D3A2869213D3D22696D6167652F706E67222626753E2E35353F753D4D6174682E6D6178282E352C752D2E31293A723D4D6174682E726F756E64284D6174682E6D617828612E77696474682C';
wwv_flow_imp.g_varchar2_table(212) := '612E686569676874292A2E38292C682829297D297D3B72657475726E206828297D66756E6374696F6E20632874297B76617220653D746869733B746869732E6366673D742C746869732E696E7075743D646F63756D656E742E676574456C656D656E7442';
wwv_flow_imp.g_varchar2_table(213) := '79496428742E6974656D292C746869732E726F6F743D646F63756D656E742E676574456C656D656E744279496428742E6974656D2B225F4D504C555322292C746869732E66656174757265733D28742E66656174757265737C7C2222292E73706C697428';
wwv_flow_imp.g_varchar2_table(214) := '223A22292C746869732E617564696F4F7074733D28742E617564696F4F7074696F6E737C7C2222292E73706C697428223A22292C746869732E6B696E64733D537472696E6728742E6D6F64657C7C22415544494F22292E746F4C6F776572436173652829';
wwv_flow_imp.g_varchar2_table(215) := '2E73706C697428223A22292E66696C7465722866756E6374696F6E2869297B72657475726E20693D3D3D22617564696F227C7C693D3D3D22766964656F227C7C693D3D3D22696D616765227D292C746869732E6B696E64732E6C656E6774687C7C287468';
wwv_flow_imp.g_varchar2_table(216) := '69732E6B696E64733D5B22617564696F225D292C746869732E6B696E643D746869732E6B696E64735B305D2C746869732E746F6F6C733D537472696E6728742E696D616765546F6F6C737C7C2222292E73706C697428223A22292E66696C74657228426F';
wwv_flow_imp.g_varchar2_table(217) := '6F6C65616E292C746869732E666163696E673D742E63616D6572613D3D3D2275736572223F2275736572223A22656E7669726F6E6D656E74222C746869732E73746174653D2269646C65222C746869732E6974656D733D28742E6974656D737C7C5B5D29';
wwv_flow_imp.g_varchar2_table(218) := '2E6D61702866756E6374696F6E2869297B72657475726E20692E70656E64696E673D21302C697D292C746869732E73617665643D742E73617665647C7C5B5D2C746869732E696E697469616C3D746869732E696E7075742E76616C75652C746869732E64';
wwv_flow_imp.g_varchar2_table(219) := '697361626C65643D21312C746869732E64726166744B65793D226D706C75733A222B28742E61707049647C7C2222292B223A222B28742E7061676549647C7C2222292B223A222B742E6974656D2C746869732E737570706F727465643D21212877696E64';
wwv_flow_imp.g_varchar2_table(220) := '6F772E4D656469615265636F7264657226266E6176696761746F722E6D656469614465766963657326266E6176696761746F722E6D65646961446576696365732E676574557365724D65646961262677696E646F772E6973536563757265436F6E746578';
wwv_flow_imp.g_varchar2_table(221) := '74213D3D2131292C746869732E53523D77696E646F772E5370656563685265636F676E6974696F6E7C7C77696E646F772E7765626B69745370656563685265636F676E6974696F6E2C746869732E6C616E67733D537472696E6728742E7472616E736372';
wwv_flow_imp.g_varchar2_table(222) := '6970744C616E6775616765737C7C2222292E73706C6974282F5B2C3B3A5C735D2B2F292E66696C7465722866756E6374696F6E2869297B72657475726E2065652E696E6465784F662869293E3D307D292C746869732E6C616E67732E6C656E6774687C7C';
wwv_flow_imp.g_varchar2_table(223) := '28746869732E6C616E67733D5B2F5E61722F692E7465737428646F63756D656E742E646F63756D656E74456C656D656E742E6C616E677C7C2222293F2261722D5341223A22656E2D5553225D293B7472797B746869732E6C616E673D6C6F63616C53746F';
wwv_flow_imp.g_varchar2_table(224) := '726167652E6765744974656D28226D706C75732D6C616E673A222B742E6974656D297D63617463687B746869732E6C616E673D6E756C6C7D746869732E6C616E67732E696E6465784F6628746869732E6C616E67293C30262628746869732E6C616E673D';
wwv_flow_imp.g_varchar2_table(225) := '746869732E6C616E67735B305D292C746869732E6275696C6428292C746869732E73796E6328292C746869732E686173282273776974636843616D657261222926266E6176696761746F722E6D656469614465766963657326266E6176696761746F722E';
wwv_flow_imp.g_varchar2_table(226) := '6D65646961446576696365732E656E756D65726174654465766963657326266E6176696761746F722E6D65646961446576696365732E656E756D65726174654465766963657328292E7468656E2866756E6374696F6E2869297B652E63616D657261733D';
wwv_flow_imp.g_varchar2_table(227) := '692E66696C7465722866756E6374696F6E286E297B72657475726E206E2E6B696E643D3D3D22766964656F696E707574227D292E6C656E6774682C652E73796E6328297D292E63617463682866756E6374696F6E28297B7D292C742E726561644F6E6C79';
wwv_flow_imp.g_varchar2_table(228) := '7C7C746869732E7265636F76657228297D632E70726F746F747970652E6861733D66756E6374696F6E2874297B72657475726E20746869732E66656174757265732E696E6465784F662874293E3D307D2C632E70726F746F747970652E7175616C697479';
wwv_flow_imp.g_varchar2_table(229) := '3D66756E6374696F6E28297B76617220743D746869732E6366672E7175616C6974793D3D3D22435553544F4D223F746869732E6366673A62745B746869732E6366672E7175616C6974795D7C7C62742E42414C414E4345443B72657475726E7B61756469';
wwv_flow_imp.g_varchar2_table(230) := '6F4B6270733A2B742E617564696F4B6270737C7C34382C766964656F4B6270733A2B742E766964656F4B6270737C7C3930302C766964656F4865696768743A2B742E766964656F4865696768747C7C3438302C6670733A2B742E6670737C7C32347D7D2C';
wwv_flow_imp.g_varchar2_table(231) := '632E70726F746F747970652E617564696F4B6270733D66756E6374696F6E2874297B76617220653D746869732E7175616C69747928292E617564696F4B6270733B72657475726E2F6D70342F692E7465737428743D3D3D766F696420303F427428746869';
wwv_flow_imp.g_varchar2_table(232) := '732E6B696E642C746869732E6366672E666F726D6174293A74293F4D6174682E6D61782839362C65293A657D2C632E70726F746F747970652E77697468536F756E643D66756E6374696F6E28297B72657475726E20746869732E6B696E643D3D3D226175';
wwv_flow_imp.g_varchar2_table(233) := '64696F227C7C746869732E6B696E643D3D3D22766964656F222626746869732E617564696F4F7074732E696E6465784F662822766964656F536F756E6422293E3D307D2C632E70726F746F747970652E63616D6572613D66756E6374696F6E28297B7265';
wwv_flow_imp.g_varchar2_table(234) := '7475726E20746869732E6B696E64213D3D22617564696F227D2C632E70726F746F747970652E7472616E736372696265733D66756E6374696F6E28297B72657475726E20746869732E6366672E7472616E736372697074696F6E3D3D3D224C4956452226';
wwv_flow_imp.g_varchar2_table(235) := '26746869732E6B696E643D3D3D22617564696F227D2C632E70726F746F747970652E6275696C643D66756E6374696F6E28297B76617220743D746869732C653D746869732E6366672C693D746869732E726F6F742C6E3D652E627574746F6E733D3D3D22';
wwv_flow_imp.g_varchar2_table(236) := '5448454D45223B692E636C6173734C6973742E61646428226D706C75732D2D222B28652E7374796C653D3D3D22434F4D50414354223F22636F6D70616374223A2266756C6C2229292C692E636C6173734C6973742E746F67676C6528226D706C75732D2D';
wwv_flow_imp.g_varchar2_table(237) := '7468656D652D627574746F6E73222C6E292C692E696E6E657248544D4C3D22222C746869732E7365673D662822646976222C226D706C75732D736567222C7B726F6C653A2267726F7570222C22617269612D6C6162656C223A6F28224B494E445322297D';
wwv_flow_imp.g_varchar2_table(238) := '292C746869732E73656742746E733D7B7D2C746869732E6B696E64732E666F72456163682866756E6374696F6E2873297B76617220723D4728226D706C75732D7365672D62746E206D706C75732D7365672D222B732C7B617564696F3A2266612D6D6963';
wwv_flow_imp.g_varchar2_table(239) := '726F70686F6E65222C766964656F3A2266612D766964656F2D63616D657261222C696D6167653A2266612D63616D657261227D5B735D2C6F28732E746F557070657243617365282929293B722E6164644576656E744C697374656E65722822636C69636B';
wwv_flow_imp.g_varchar2_table(240) := '222C66756E6374696F6E28297B742E7365744B696E642873297D292C742E73656742746E735B735D3D722C742E7365672E617070656E644368696C642872297D292C746869732E6C616E6753656C3D66282273656C656374222C226D706C75732D6C616E';
wwv_flow_imp.g_varchar2_table(241) := '67222C7B22617269612D6C6162656C223A6F28225452414E5343524950545F4C414E475541474522292C7469746C653A6F28225452414E5343524950545F4C414E475541474522297D292C746869732E6C616E67732E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(242) := '6F6E2873297B76617220723D733B7472797B723D6E657720496E746C2E446973706C61794E616D6573285B646F63756D656E742E646F63756D656E74456C656D656E742E6C616E677C7C22656E225D2C7B747970653A226C616E6775616765227D292E6F';
wwv_flow_imp.g_varchar2_table(243) := '662873297C7C737D63617463687B7D742E6C616E6753656C2E617070656E644368696C64286628226F7074696F6E222C6E756C6C2C7B76616C75653A732C746578743A722C73656C65637465643A733D3D3D742E6C616E677D29297D292C746869732E73';
wwv_flow_imp.g_varchar2_table(244) := '74617475733D6628227370616E222C226D706C75732D737461747573222C7B22617269612D6C697665223A22706F6C697465227D292C746869732E746F703D662822646976222C226D706C75732D746F70222C6E756C6C2C5B746869732E6B696E64732E';
wwv_flow_imp.g_varchar2_table(245) := '6C656E6774683E31262621652E726561644F6E6C793F746869732E7365673A6E756C6C2C746869732E6C616E6753656C2C746869732E7374617475735D292C746869732E766964656F3D662822766964656F222C226D706C75732D6C697665222C7B706C';
wwv_flow_imp.g_varchar2_table(246) := '617973696E6C696E653A21302C6D757465643A21302C6175746F706C61793A21307D292C746869732E766964656F2E6D757465643D21302C746869732E63616E7661733D66282263616E766173222C226D706C75732D77617665222C7B22617269612D68';
wwv_flow_imp.g_varchar2_table(247) := '696464656E223A2274727565227D292C746869732E74696D65723D6628227370616E222C226D706C75732D74696D6572222C7B746578743A22303A3030222C726F6C653A2274696D6572227D292C746869732E646F743D6628227370616E222C226D706C';
wwv_flow_imp.g_varchar2_table(248) := '75732D646F74222C7B22617269612D68696464656E223A2274727565227D292C746869732E6C6576656C3D6628227370616E222C226D706C75732D6C6576656C222C7B22617269612D68696464656E223A2274727565227D2C5B6628227370616E22295D';
wwv_flow_imp.g_varchar2_table(249) := '292C746869732E636F756E74646F776E3D6628227370616E222C226D706C75732D636F756E74646F776E222C7B22617269612D6C697665223A22617373657274697665227D292C746869732E73746167653D662822646976222C226D706C75732D737461';
wwv_flow_imp.g_varchar2_table(250) := '6765222C6E756C6C2C5B746869732E766964656F2C746869732E63616E7661732C662822646976222C226D706C75732D6F7665726C6179222C6E756C6C2C5B6628227370616E222C226D706C75732D726563222C6E756C6C2C5B746869732E646F742C74';
wwv_flow_imp.g_varchar2_table(251) := '6869732E74696D65725D292C746869732E6C6576656C5D292C746869732E636F756E74646F776E5D292C746869732E766964656F2E6164644576656E744C697374656E65722822726573697A65222C66756E6374696F6E28297B742E6669745374616765';
wwv_flow_imp.g_varchar2_table(252) := '28742E766964656F2E766964656F57696474682C742E766964656F2E766964656F486569676874297D292C746869732E73747446696E616C456C3D6628227370616E22292C746869732E737474496E746572696D456C3D6628227370616E222C226D706C';
wwv_flow_imp.g_varchar2_table(253) := '75732D7374742D696E746572696D22292C746869732E737474426F783D662822646976222C226D706C75732D737474222C7B22617269612D6C697665223A22706F6C697465227D2C5B746869732E73747446696E616C456C2C746869732E737474496E74';
wwv_flow_imp.g_varchar2_table(254) := '6572696D456C5D292C746869732E6D6574657246696C6C3D6628227370616E222C226D706C75732D6D657465722D66696C6C22292C746869732E6D65746572546578743D6628227370616E222C226D706C75732D6D657465722D7465787422292C746869';
wwv_flow_imp.g_varchar2_table(255) := '732E6D657465724261723D6628227370616E222C226D706C75732D6D657465722D747261636B222C7B726F6C653A2270726F6772657373626172222C22617269612D76616C75656D696E223A302C22617269612D76616C75656D6178223A3130307D2C5B';
wwv_flow_imp.g_varchar2_table(256) := '746869732E6D6574657246696C6C5D292C746869732E6D657465723D662822646976222C226D706C75732D6D65746572222C6E756C6C2C5B746869732E6D657465724261722C746869732E6D65746572546578745D292C746869732E6E6F746963653D66';
wwv_flow_imp.g_varchar2_table(257) := '2822646976222C226D706C75732D6E6F74696365222C7B726F6C653A22737461747573227D292C746869732E625265636F72643D4728226D706C75732D62746E2D2D726563206D706C75732D622D7265636F7264222C22726563222C6F28225245434F52';
wwv_flow_imp.g_varchar2_table(258) := '4422292C21312C6E292C746869732E6250617573653D4728226D706C75732D622D7061757365222C227061757365222C6F2822504155534522292C21312C6E292C746869732E6250617573652E6D706C75734B65793D2250222C746869732E6253746F70';
wwv_flow_imp.g_varchar2_table(259) := '3D4728226D706C75732D62746E2D2D73746F70206D706C75732D622D73746F70222C2273746F70222C6F282253544F5022292C21312C6E292C746869732E6253746F702E6D706C75734B65793D2253222C746869732E625377697463683D4728226D706C';
wwv_flow_imp.g_varchar2_table(260) := '75732D622D737769746368222C2266612D72656672657368222C6F28225357495443485F43414D45524122292C21302C6E292C746869732E62436C6F73653D4728226D706C75732D62746E2D2D67686F7374206D706C75732D622D636C6F7365222C2266';
wwv_flow_imp.g_varchar2_table(261) := '612D74696D6573222C6F2822434C4F53455F43414D45524122292C21312C6E292C746869732E6246696C653D4728226D706C75732D62746E2D2D67686F7374206D706C75732D622D66696C65222C2266612D75706C6F6164222C746869732E737570706F';
wwv_flow_imp.g_varchar2_table(262) := '727465643F6F282243484F4F53455F46494C4522293A6F28224445564943455F5245434F5244455222292C21312C6E292C746869732E66696C653D662822696E707574222C226D706C75732D66696C65222C7B747970653A2266696C65222C6869646465';
wwv_flow_imp.g_varchar2_table(263) := '6E3A21302C746162696E6465783A222D31222C6163636570743A746869732E6B696E64732E6D61702866756E6374696F6E2873297B72657475726E20732B222F2A227D292E6A6F696E28222C22292C636170747572653A746869732E737570706F727465';
wwv_flow_imp.g_varchar2_table(264) := '643F6E756C6C3A746869732E6B696E64735B305D3D3D3D22617564696F223F2275736572223A22656E7669726F6E6D656E74227D292C746869732E616374696F6E733D662822646976222C226D706C75732D616374696F6E73206D706C75732D61637469';
wwv_flow_imp.g_varchar2_table(265) := '6F6E732D2D6D61696E222C6E756C6C2C5B746869732E625265636F72642C746869732E6250617573652C746869732E6253746F702C746869732E625377697463682C746869732E62436C6F73652C746869732E6246696C652C746869732E66696C655D29';
wwv_flow_imp.g_varchar2_table(266) := '2C746869732E68696E743D662822646976222C226D706C75732D68696E7422292C746869732E706C617965723D662822646976222C226D706C75732D7265766965772D706C6179657222292C746869732E625573653D4728226D706C75732D62746E2D2D';
wwv_flow_imp.g_varchar2_table(267) := '7072696D617279206D706C75732D622D757365222C2266612D636865636B222C6F282255534522292C21312C6E292C746869732E62416761696E3D4728226D706C75732D622D616761696E222C2266612D756E646F222C6F2822414741494E22292C2131';
wwv_flow_imp.g_varchar2_table(268) := '2C6E292C746869732E62446973636172643D4728226D706C75732D62746E2D2D67686F7374206D706C75732D622D64697363617264222C2266612D74726173682D6F222C6F28224449534341524422292C21312C6E292C746869732E61446F776E6C6F61';
wwv_flow_imp.g_varchar2_table(269) := '643D66282261222C286E3F226D706C75732D62746E2D2D7468656D6520742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D427574746F6E2D2D6E6F554920742D427574746F6E2D2D69636F6E4C656674223A226D706C75732D62746E20';
wwv_flow_imp.g_varchar2_table(270) := '6D706C75732D62746E2D2D67686F737422292B22206D706C75732D622D646F776E6C6F6164222C7B687265663A2223227D2C5B6628227370616E222C226D706C75732D692066612066612D646F776E6C6F6164222B286E3F2220742D49636F6E20742D49';
wwv_flow_imp.g_varchar2_table(271) := '636F6E2D2D6C656674223A2222292C7B22617269612D68696464656E223A2274727565227D292C6628227370616E222C226D706C75732D62746E2D6C6162656C222B286E3F2220742D427574746F6E2D6C6162656C223A2222292C7B746578743A6F2822';
wwv_flow_imp.g_varchar2_table(272) := '444F574E4C4F414422297D295D292C746869732E7265766965774D6574613D6628227370616E222C226D706C75732D7265766965772D6D65746122292C746869732E726576696577546578743D6628227465787461726561222C226D706C75732D747261';
wwv_flow_imp.g_varchar2_table(273) := '6E73637269707420746578745F6669656C6420617065782D6974656D2D7465787461726561222C7B726F77733A332C6D61786C656E6774683A54742C706C616365686F6C6465723A6F28225452414E5343524950545F504C414345484F4C44455222292C';
wwv_flow_imp.g_varchar2_table(274) := '69643A652E6974656D2B225F5452414E534352495054227D292C746869732E72657669657754657874426F783D662822646976222C226D706C75732D7472616E7363726970742D626F78222C6E756C6C2C5B6628226C6162656C222C226D706C75732D74';
wwv_flow_imp.g_varchar2_table(275) := '72616E7363726970742D6C6162656C222C7B666F723A652E6974656D2B225F5452414E534352495054222C746578743A6F28225452414E53435249505422297D292C746869732E726576696577546578745D292C746869732E7265766965775469746C65';
wwv_flow_imp.g_varchar2_table(276) := '3D662822646976222C226D706C75732D7265766965772D7469746C65222C7B746578743A6F28225245564945575F5449544C4522297D292C746869732E6275696C64456469746F72286E292C746869732E7265766965773D662822646976222C226D706C';
wwv_flow_imp.g_varchar2_table(277) := '75732D726576696577222C6E756C6C2C5B746869732E7265766965775469746C652C746869732E706C617965722C746869732E70686F746F426F782C662822646976222C226D706C75732D7265766965772D626172222C6E756C6C2C5B746869732E7265';
wwv_flow_imp.g_varchar2_table(278) := '766965774D6574615D292C746869732E72657669657754657874426F782C662822646976222C226D706C75732D616374696F6E73222C6E756C6C2C5B746869732E625573652C746869732E62416761696E2C746869732E62446973636172642C74686973';
wwv_flow_imp.g_varchar2_table(279) := '2E61446F776E6C6F61645D295D292C746869732E6C6973743D662822756C222C226D706C75732D6C69737422292C5B746869732E746F702C746869732E73746167652C746869732E737474426F782C746869732E6D657465722C746869732E6E6F746963';
wwv_flow_imp.g_varchar2_table(280) := '652C746869732E616374696F6E732C746869732E7265766965772C746869732E68696E742C746869732E6C6973745D2E666F72456163682866756E6374696F6E2873297B692E617070656E644368696C642873297D292C746869732E6C616E6753656C2E';
wwv_flow_imp.g_varchar2_table(281) := '6164644576656E744C697374656E657228226368616E6765222C66756E6374696F6E28297B742E6C616E673D742E6C616E6753656C2E76616C75653B7472797B6C6F63616C53746F726167652E7365744974656D28226D706C75732D6C616E673A222B65';
wwv_flow_imp.g_varchar2_table(282) := '2E6974656D2C742E6C616E67297D63617463687B7D7D292C746869732E625265636F72642E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E737461727428297D292C746869732E6250617573652E616464';
wwv_flow_imp.g_varchar2_table(283) := '4576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E746F67676C65506175736528297D292C746869732E6253746F702E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E';
wwv_flow_imp.g_varchar2_table(284) := '73746F7028297D292C746869732E625377697463682E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E73776974636843616D65726128297D292C746869732E62436C6F73652E6164644576656E744C6973';
wwv_flow_imp.g_varchar2_table(285) := '74656E65722822636C69636B222C66756E6374696F6E28297B742E72656C6561736528292C742E7365745374617465282269646C6522297D292C746869732E6246696C652E6164644576656E744C697374656E65722822636C69636B222C66756E637469';
wwv_flow_imp.g_varchar2_table(286) := '6F6E28297B742E66696C652E636C69636B28297D292C746869732E66696C652E6164644576656E744C697374656E657228226368616E6765222C66756E6374696F6E28297B742E66696C652E66696C65735B305D2626742E75736546696C6528742E6669';
wwv_flow_imp.g_varchar2_table(287) := '6C652E66696C65735B305D292C742E66696C652E76616C75653D22227D292C746869732E625573652E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E61636365707428297D292C746869732E6241676169';
wwv_flow_imp.g_varchar2_table(288) := '6E2E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E64697363617264282130297D292C746869732E62446973636172642E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F';
wwv_flow_imp.g_varchar2_table(289) := '6E28297B742E64697363617264282131297D292C746869732E61446F776E6C6F61642E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2873297B69662821742E65647C7C742E61446F776E6C6F61642E6D706C757352';
wwv_flow_imp.g_varchar2_table(290) := '65616479297B742E61446F776E6C6F61642E6D706C757352656164793D21313B72657475726E7D732E70726576656E7444656661756C7428292C742E65644578706F727428292E7468656E2866756E6374696F6E2872297B742E646C55726C262655524C';
wwv_flow_imp.g_varchar2_table(291) := '2E7265766F6B654F626A65637455524C28742E646C55726C292C742E646C55726C3D55524C2E6372656174654F626A65637455524C28722E626C6F62292C742E61446F776E6C6F61642E687265663D742E646C55726C2C742E61446F776E6C6F61642E73';
wwv_flow_imp.g_varchar2_table(292) := '65744174747269627574652822646F776E6C6F6164222C742E70686F746F4E616D6528722E626C6F622E7479706529292C742E61446F776E6C6F61642E6D706C757352656164793D21302C742E61446F776E6C6F61642E636C69636B28297D297D292C69';
wwv_flow_imp.g_varchar2_table(293) := '2E6164644576656E744C697374656E657228226B6579646F776E222C66756E6374696F6E2873297B6966282128732E6374726C4B65797C7C732E6D6574614B65797C7C732E616C744B65797C7C2F5E2854455854415245417C494E5055547C53454C4543';
wwv_flow_imp.g_varchar2_table(294) := '5429242F2E7465737428732E7461726765742E7461674E616D652929297B76617220723D28732E6B65797C7C2222292E746F4C6F7765724361736528293B723D3D3D227022262628742E73746174653D3D3D227265636F7264696E67227C7C742E737461';
wwv_flow_imp.g_varchar2_table(295) := '74653D3D3D227061757365642229262628732E70726576656E7444656661756C7428292C742E746F67676C6550617573652829292C723D3D3D227322262628742E73746174653D3D3D227265636F7264696E67227C7C742E73746174653D3D3D22706175';
wwv_flow_imp.g_varchar2_table(296) := '7365642229262628732E70726576656E7444656661756C7428292C742E73746F702829297D7D292C746869732E72656E6465724C69737428297D2C632E70726F746F747970652E73657453746174653D66756E6374696F6E2874297B746869732E737461';
wwv_flow_imp.g_varchar2_table(297) := '74653D742C746869732E726F6F742E7365744174747269627574652822646174612D7374617465222C74292C746869732E73796E6328297D2C632E70726F746F747970652E7365744B696E643D66756E6374696F6E2874297B746869732E737461746521';
wwv_flow_imp.g_varchar2_table(298) := '3D3D2269646C65227C7C746869732E6B696E643D3D3D747C7C746869732E6B696E64732E696E6465784F662874293C307C7C28746869732E6B696E643D742C746869732E73796E632829297D2C632E70726F746F747970652E66756C6C3D66756E637469';
wwv_flow_imp.g_varchar2_table(299) := '6F6E28297B72657475726E20746869732E6974656D732E6C656E6774683E3D4D6174682E6D617828312C746869732E6366672E6D6178436F756E747C7C31297D2C632E70726F746F747970652E66697453746167653D66756E6374696F6E28742C65297B';
wwv_flow_imp.g_varchar2_table(300) := '69662821746869732E63616D65726128297C7C21747C7C2165297B746869732E73746167652E7374796C652E617370656374526174696F3D22222C746869732E73746167652E7374796C652E6D617857696474683D22223B72657475726E7D746869732E';
wwv_flow_imp.g_varchar2_table(301) := '73746167652E7374796C652E617370656374526174696F3D742B22202F20222B652C746869732E73746167652E7374796C652E6D617857696474683D2263616C632836307668202A20222B28742F65292E746F46697865642834292B2229227D2C632E70';
wwv_flow_imp.g_varchar2_table(302) := '726F746F747970652E73796E633D66756E6374696F6E28297B76617220743D746869732E73746174652C653D746869732E6366672C693D652E726561644F6E6C797C7C746869732E64697361626C65642C6E3D743D3D3D226F70656E696E67227C7C743D';
wwv_flow_imp.g_varchar2_table(303) := '3D3D227265616479227C7C743D3D3D22636F756E74646F776E227C7C743D3D3D227265636F7264696E67227C7C743D3D3D22706175736564227C7C743D3D3D2273746F7070696E67222C733D743D3D3D226F70656E696E67227C7C743D3D3D22636F756E';
wwv_flow_imp.g_varchar2_table(304) := '74646F776E227C7C743D3D3D227265636F7264696E67227C7C743D3D3D22706175736564227C7C743D3D3D2273746F7070696E67222C723D746869732E6B696E643D3D3D22766964656F222C753D746869732E6B696E643D3D3D22696D616765222C6C3D';
wwv_flow_imp.g_varchar2_table(305) := '746869732E63616D65726128292C683D746869733B746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D766964656F222C6C292C746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D';
wwv_flow_imp.g_varchar2_table(306) := '2D696D616765222C75292C746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D617564696F222C216C292C746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D64697361626C6564';
wwv_flow_imp.g_varchar2_table(307) := '222C746869732E64697361626C6564292C746869732E726F6F742E636C6173734C6973742E746F67676C6528226D706C75732D2D6D6972726F72222C6C2626746869732E666163696E673D3D3D2275736572222626746869732E68617328226D6972726F';
wwv_flow_imp.g_varchar2_table(308) := '722229292C4F626A6563742E6B65797328746869732E73656742746E73292E666F72456163682866756E6374696F6E284F297B682E73656742746E735B4F5D2E7365744174747269627574652822617269612D70726573736564222C537472696E67284F';
wwv_flow_imp.g_varchar2_table(309) := '3D3D3D682E6B696E6429292C682E73656742746E735B4F5D2E64697361626C65643D74213D3D2269646C65227C7C682E64697361626C65647D292C5328746869732E6C616E6753656C2C21692626746869732E7472616E73637269626573282926267468';
wwv_flow_imp.g_varchar2_table(310) := '69732E6C616E67732E6C656E6774683E3126262121746869732E5352292C746869732E6C616E6753656C2E64697361626C65643D74213D3D2269646C6522262674213D3D227265616479223B76617220613D7B6F70656E696E673A6F2822535441525449';
wwv_flow_imp.g_varchar2_table(311) := '4E4722292C72656164793A6F2822524541445922292C636F756E74646F776E3A6F2822524541445922292C7265636F7264696E673A6F28225245434F5244494E4722292C7061757365643A6F282250415553454422292C73746F7070696E673A6F282246';
wwv_flow_imp.g_varchar2_table(312) := '494E495348494E4722292C7265766965773A6F282252455649455722292C75706C6F6164696E673A652E7472616E736372697074696F6E3D3D3D22534552564552222626746869732E75706C6F6164696E67417564696F3F6F28225452414E5343524942';
wwv_flow_imp.g_varchar2_table(313) := '494E475F53455256455222293A6F282255504C4F4144494E4722297D5B745D7C7C22223B746869732E7374617475732E74657874436F6E74656E743D612C746869732E7374617475732E636C6173734E616D653D226D706C75732D737461747573206D70';
wwv_flow_imp.g_varchar2_table(314) := '6C75732D7374617475732D2D222B742C5328746869732E7374617475732C212161292C5328746869732E746F702C2169262628746869732E6B696E64732E6C656E6774683E317C7C2121617C7C21746869732E6C616E6753656C2E68696464656E29292C';
wwv_flow_imp.g_varchar2_table(315) := '5328746869732E73746167652C216926266E292C5328746869732E766964656F2C6C292C5328746869732E63616E7661732C216C2626746869732E68617328226C6576656C4D657465722229292C5328746869732E6C6576656C2C722626746869732E68';
wwv_flow_imp.g_varchar2_table(316) := '617328226C6576656C4D6574657222292626746869732E77697468536F756E642829292C5328746869732E73746167652E717565727953656C6563746F7228222E6D706C75732D72656322292C2175292C5328746869732E737474426F782C2169262674';
wwv_flow_imp.g_varchar2_table(317) := '6869732E7472616E736372696265732829262628743D3D3D227265636F7264696E67227C7C743D3D3D22706175736564227C7C743D3D3D2273746F7070696E6722292626212128746869732E73747446696E616C456C2E74657874436F6E74656E747C7C';
wwv_flow_imp.g_varchar2_table(318) := '746869732E737474496E746572696D456C2E74657874436F6E74656E747C7C746869732E73747429292C5328746869732E6D657465722C2169262673293B76617220643D746869732E737570706F7274656426262169262621746869732E66756C6C2829';
wwv_flow_imp.g_varchar2_table(319) := '3B5328746869732E616374696F6E732C2169262674213D3D2272657669657722262674213D3D2275706C6F6164696E6722292C5328746869732E625265636F72642C64262628743D3D3D2269646C65227C7C743D3D3D2272656164792229292C753F7374';
wwv_flow_imp.g_varchar2_table(320) := '28746869732E625265636F72642C2266612D63616D657261222C6F28743D3D3D227265616479223F2243415054555245223A2254414B455F50484F544F2229293A737428746869732E625265636F72642C74213D3D227265616479222626723F2266612D';
wwv_flow_imp.g_varchar2_table(321) := '766964656F2D63616D657261223A22726563222C6F28743D3D3D227265616479223F225354415254223A723F224F50454E5F43414D455241223A225245434F52442229292C746869732E625265636F72642E636C6173734C6973742E746F67676C652822';
wwv_flow_imp.g_varchar2_table(322) := '6D706C75732D62746E2D2D73687574746572222C752626743D3D3D22726561647922292C5328746869732E6250617573652C746869732E686173282270617573652229262673292C746869732E6250617573652E64697361626C65643D74213D3D227265';
wwv_flow_imp.g_varchar2_table(323) := '636F7264696E6722262674213D3D22706175736564222C737428746869732E6250617573652C743D3D3D22706175736564223F22706C6179223A227061757365222C6F28743D3D3D22706175736564223F22524553554D45223A2250415553452229292C';
wwv_flow_imp.g_varchar2_table(324) := '746869732E6250617573652E636C6173734C6973742E746F67676C6528226D706C75732D62746E2D2D7072696D617279222C743D3D3D2270617573656422262621746869732E6250617573652E6D706C75735468656D65292C5328746869732E6253746F';
wwv_flow_imp.g_varchar2_table(325) := '702C73292C746869732E6253746F702E64697361626C65643D743D3D3D2273746F7070696E67222C737428746869732E6253746F702C2273746F70222C6F28743D3D3D226F70656E696E67227C7C743D3D3D22636F756E74646F776E223F2243414E4345';
wwv_flow_imp.g_varchar2_table(326) := '4C223A2253544F502229292C5328746869732E625377697463682C6C2626743D3D3D227265616479222626746869732E686173282273776974636843616D65726122292626746869732E63616D657261733E31292C5328746869732E62436C6F73652C74';
wwv_flow_imp.g_varchar2_table(327) := '3D3D3D22726561647922292C5328746869732E6246696C652C2169262621746869732E66756C6C28292626743D3D3D2269646C6522262628746869732E686173282275706C6F616422297C7C21746869732E737570706F7274656429293B76617220703D';
wwv_flow_imp.g_varchar2_table(328) := '2121746869732E65643B5328746869732E7265766965772C743D3D3D2272657669657722292C5328746869732E706C617965722C2170292C5328746869732E70686F746F426F782C70292C746869732E7265766965775469746C652E74657874436F6E74';
wwv_flow_imp.g_varchar2_table(329) := '656E743D6F28703F2250484F544F5F5449544C45223A225245564945575F5449544C4522292C5328746869732E72657669657754657874426F782C2170262628746869732E7472616E7363726962657328297C7C2121746869732E726576696577546578';
wwv_flow_imp.g_varchar2_table(330) := '742E76616C756529292C746869732E625573652E64697361626C65643D2121746869732E746F6F4269677C7C2121746869732E6564576F726B696E672C737428746869732E625573652C746869732E6661696C65643F2266612D72656672657368223A22';
wwv_flow_imp.g_varchar2_table(331) := '66612D636865636B222C746869732E6661696C65643F6F2822524554525922293A6F28703F225553455F50484F544F223A225553452229292C737428746869732E62416761696E2C703F2266612D63616D657261223A2266612D756E646F222C6F28703F';
wwv_flow_imp.g_varchar2_table(332) := '22524554414B45223A22414741494E2229292C5328746869732E62416761696E2C21707C7C746869732E737570706F72746564292C5328746869732E61446F776E6C6F61642C746869732E6861732822646F776E6C6F616422297C7C2121746869732E66';
wwv_flow_imp.g_varchar2_table(333) := '61696C65647C7C2121746869732E746F6F426967292C6C7C7C746869732E666974537461676528302C30292C746869732E6250617573652E6D706C75735468656D652626746869732E6250617573652E636C6173734C6973742E746F67676C652822742D';
wwv_flow_imp.g_varchar2_table(334) := '427574746F6E2D2D686F74222C743D3D3D2270617573656422293B76617220673D22223B69662821692626743D3D3D2269646C652229696628746869732E66756C6C282929673D652E6D6178436F756E743E313F6F28224D41585F434F554E54222C652E';
wwv_flow_imp.g_varchar2_table(335) := '6D6178436F756E74293A6F28224D41585F434F554E545F4F4E4522293B656C73652069662821746869732E737570706F7274656429673D6F28224E4F545F535550504F5254454422293B656C7365206966287529673D6F28224C494D49545F48494E5422';
wwv_flow_imp.g_varchar2_table(336) := '2C4428652E6D6178427974657329293B656C73657B76617220453D746869732E7175616C69747928292C523D28746869732E77697468536F756E6428293F746869732E617564696F4B62707328293A30292B28723F452E766964656F4B6270733A30292C';
wwv_flow_imp.g_varchar2_table(337) := '6B3D523F652E6D617842797465732A382F28522A316533293A302C483D652E6D61784475726174696F6E3F6F28224C494D49545F48494E545F54494D45222C5828652E6D61784475726174696F6E292C4428652E6D6178427974657329293A6F28224C49';
wwv_flow_imp.g_varchar2_table(338) := '4D49545F48494E54222C4428652E6D6178427974657329293B673D482B286B26262821652E6D61784475726174696F6E7C7C6B3C652E6D61784475726174696F6E293F22205C78423720222B6F28224341504143495459222C6E65286B29293A2222297D';
wwv_flow_imp.g_varchar2_table(339) := '746869732E68696E742E74657874436F6E74656E743D672C5328746869732E68696E742C212167297D2C632E70726F746F747970652E7361793D66756E6374696F6E28742C65297B746869732E6E6F746963652E74657874436F6E74656E743D22222C74';
wwv_flow_imp.g_varchar2_table(340) := '262628746869732E6E6F746963652E617070656E644368696C6428437428653D3D3D226572726F72223F2266612D6578636C616D6174696F6E2D636972636C65223A653D3D3D227761726E223F2266612D6578636C616D6174696F6E2D747269616E676C';
wwv_flow_imp.g_varchar2_table(341) := '65223A2266612D696E666F2D636972636C652229292C746869732E6E6F746963652E617070656E644368696C64286628227370616E222C6E756C6C2C7B746578743A747D2929292C746869732E6E6F746963652E636C6173734E616D653D226D706C7573';
wwv_flow_imp.g_varchar2_table(342) := '2D6E6F74696365222B28653F22206D706C75732D6E6F746963652D2D222B653A2222292C746869732E6E6F746963652E7365744174747269627574652822726F6C65222C653D3D3D226572726F72227C7C653D3D3D227761726E223F22616C657274223A';
wwv_flow_imp.g_varchar2_table(343) := '2273746174757322292C5328746869732E6E6F746963652C212174297D2C632E70726F746F747970652E666972653D66756E6374696F6E28742C65297B617065782E6576656E742E7472696767657228746869732E696E7075742C226D65646961706C75';
wwv_flow_imp.g_varchar2_table(344) := '73222B742C6E742E657874656E64287B6974656D3A746869732E6366672E6974656D7D2C657C7C7B7D29297D2C632E70726F746F747970652E666F6375734E6578743D66756E6374696F6E28297B76617220743D746869732E625265636F72642E686964';
wwv_flow_imp.g_varchar2_table(345) := '64656E3F746869732E6C6973742E717565727953656C6563746F7228222E6D706C75732D726F773A6C6173742D6368696C6420627574746F6E22293A746869732E625265636F72643B742626742E666F63757328297D2C632E70726F746F747970652E63';
wwv_flow_imp.g_varchar2_table(346) := '6F6E73747261696E74733D66756E6374696F6E28297B76617220743D746869732E7175616C69747928292C653D746869732E617564696F4F7074732C693D21312C6E3D21313B696628746869732E77697468536F756E642829262628693D7B6563686F43';
wwv_flow_imp.g_varchar2_table(347) := '616E63656C6C6174696F6E3A652E696E6465784F6628226563686F43616E63656C6C6174696F6E22293E3D302C6E6F6973655375707072657373696F6E3A652E696E6465784F6628226E6F6973655375707072657373696F6E22293E3D302C6175746F47';
wwv_flow_imp.g_varchar2_table(348) := '61696E436F6E74726F6C3A652E696E6465784F6628226175746F4761696E436F6E74726F6C22293E3D307D2C652E696E6465784F6628226D6F6E6F22293E3D30262628692E6368616E6E656C436F756E743D7B696465616C3A317D29292C746869732E6B';
wwv_flow_imp.g_varchar2_table(349) := '696E643D3D3D22766964656F22296E3D7B666163696E674D6F64653A7B696465616C3A746869732E666163696E677D2C6865696768743A7B696465616C3A742E766964656F4865696768747D2C77696474683A7B696465616C3A4D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(350) := '28742E766964656F4865696768742A31362F39297D2C6672616D65526174653A7B696465616C3A742E6670732C6D61783A742E6670737D7D3B656C736520696628746869732E6B696E643D3D3D22696D61676522297B76617220733D4D6174682E6D6178';
wwv_flow_imp.g_varchar2_table(351) := '28313238302C746869732E6366672E696D6167654D6178536964657C7C31393230293B6E3D7B666163696E674D6F64653A7B696465616C3A746869732E666163696E677D2C77696474683A7B696465616C3A737D2C6865696768743A7B696465616C3A4D';
wwv_flow_imp.g_varchar2_table(352) := '6174682E726F756E6428732A332F34297D7D7D72657475726E7B617564696F3A692C766964656F3A6E7D7D2C632E70726F746F747970652E6F70656E3D66756E6374696F6E28297B76617220743D746869733B72657475726E20746869732E7361792822';
wwv_flow_imp.g_varchar2_table(353) := '22292C746869732E63616E63656C6C65643D21312C746869732E74696D65722E74657874436F6E74656E743D22303A3030222C746869732E6D6574657246696C6C2E7374796C652E77696474683D2230222C746869732E6D65746572546578742E746578';
wwv_flow_imp.g_varchar2_table(354) := '74436F6E74656E743D6F28224F46222C442830292C4428746869732E6366672E6D6178427974657329292C746869732E736574537461746528226F70656E696E6722292C66742822706C61792D616E642D7265636F726422292C6E6176696761746F722E';
wwv_flow_imp.g_varchar2_table(355) := '6D65646961446576696365732E676574557365724D6564696128746869732E636F6E73747261696E74732829292E7468656E2866756E6374696F6E2865297B696628742E63616E63656C6C6564297468726F7720652E676574547261636B7328292E666F';
wwv_flow_imp.g_varchar2_table(356) := '72456163682866756E6374696F6E286E297B6E2E73746F7028297D292C6E6577204572726F72282263616E63656C6C656422293B696628742E73747265616D3D652C652E676574547261636B7328292E666F72456163682866756E6374696F6E286E297B';
wwv_flow_imp.g_varchar2_table(357) := '6E2E6164644576656E744C697374656E65722822656E646564222C66756E6374696F6E28297B742E747261636B456E6465642865297D297D292C742E63616D6572612829297B76617220693D652E676574566964656F547261636B7328295B305D262665';
wwv_flow_imp.g_varchar2_table(358) := '2E676574566964656F547261636B7328295B305D2E67657453657474696E67733F652E676574566964656F547261636B7328295B305D2E67657453657474696E677328293A7B7D3B742E666974537461676528692E77696474682C692E68656967687429';
wwv_flow_imp.g_varchar2_table(359) := '2C742E766964656F2E7372634F626A6563743D652C742E766964656F2E636F6E74726F6C733D21312C742E766964656F2E706C617928292E63617463682866756E6374696F6E28297B7D297D652E676574417564696F547261636B7328292E6C656E6774';
wwv_flow_imp.g_varchar2_table(360) := '68262628742E6D65746572537461727428292C652E676574417564696F547261636B7328292E666F72456163682866756E6374696F6E286E297B6E2E6164644576656E744C697374656E657228226D757465222C66756E6374696F6E28297B742E736F75';
wwv_flow_imp.g_varchar2_table(361) := '6E644C6F73742865297D297D29292C742E636F756E7443616D6572617328297D292E63617463682866756E6374696F6E2865297B696628742E63616E63656C6C6564297468726F7720653B742E72656C6561736528292C742E7365745374617465282269';
wwv_flow_imp.g_varchar2_table(362) := '646C6522293B76617220693D65262628652E6E616D653D3D3D224E6F74416C6C6F7765644572726F72227C7C652E6E616D653D3D3D2253656375726974794572726F7222292C6E3D65262628652E6E616D653D3D3D224E6F74466F756E644572726F7222';
wwv_flow_imp.g_varchar2_table(363) := '7C7C652E6E616D653D3D3D224F766572636F6E73747261696E65644572726F7222293B7468726F7720742E73617928693F6F28224E4F5F5045524D495353494F4E22293A6E3F6F28224E4F5F44455649434522293A652626652E6D6573736167657C7C6F';
wwv_flow_imp.g_varchar2_table(364) := '28224E4F545F535550504F5254454422292C226572726F7222292C742E6669726528226572726F72222C7B726561736F6E3A652626652E6E616D652C6D6573736167653A652626652E6D6573736167657D292C657D297D2C632E70726F746F747970652E';
wwv_flow_imp.g_varchar2_table(365) := '747261636B456E6465643D66756E6374696F6E2874297B743D3D3D746869732E73747265616D262628746869732E73746174653D3D3D227265636F7264696E67227C7C746869732E73746174653D3D3D22706175736564223F28746869732E736179286F';
wwv_flow_imp.g_varchar2_table(366) := '28224445564943455F454E44454422292C227761726E22292C746869732E73746F7028226465766963652229293A28746869732E73746174653D3D3D227265616479227C7C746869732E73746174653D3D3D22636F756E74646F776E2229262628636C65';
wwv_flow_imp.g_varchar2_table(367) := '6172496E74657276616C28746869732E636454696D6572292C746869732E636F756E74646F776E2E74657874436F6E74656E743D22222C746869732E72656C6561736528292C746869732E7365745374617465282269646C6522292C746869732E736179';
wwv_flow_imp.g_varchar2_table(368) := '286F28224445564943455F454E44454422292C227761726E222929297D2C632E70726F746F747970652E72656C656173653D66756E6374696F6E28297B76617220743D2121746869732E73747265616D3B746869732E73747265616D2626746869732E73';
wwv_flow_imp.g_varchar2_table(369) := '747265616D2E676574547261636B7328292E666F72456163682866756E6374696F6E2865297B652E73746F7028297D292C746869732E73747265616D3D6E756C6C2C746869732E766964656F2E7372634F626A6563743D6E756C6C2C746869732E6D6574';
wwv_flow_imp.g_varchar2_table(370) := '657253746F7028292C74262666742822706C61796261636B22297D2C632E70726F746F747970652E73776974636843616D6572613D66756E6374696F6E28297B76617220743D746869733B746869732E73746174653D3D3D227265616479222626287468';
wwv_flow_imp.g_varchar2_table(371) := '69732E666163696E673D746869732E666163696E673D3D3D2275736572223F22656E7669726F6E6D656E74223A2275736572222C746869732E72656C6561736528292C746869732E6F70656E28292E7468656E2866756E6374696F6E28297B742E736574';
wwv_flow_imp.g_varchar2_table(372) := '53746174652822726561647922297D292E63617463682866756E6374696F6E28297B7D29297D2C632E70726F746F747970652E636F756E7443616D657261733D66756E6374696F6E28297B76617220743D746869733B216E6176696761746F722E6D6564';
wwv_flow_imp.g_varchar2_table(373) := '6961446576696365737C7C216E6176696761746F722E6D65646961446576696365732E656E756D6572617465446576696365737C7C6E6176696761746F722E6D65646961446576696365732E656E756D65726174654465766963657328292E7468656E28';
wwv_flow_imp.g_varchar2_table(374) := '66756E6374696F6E2865297B742E63616D657261733D652E66696C7465722866756E6374696F6E2869297B72657475726E20692E6B696E643D3D3D22766964656F696E707574227D292E6C656E6774682C742E73796E6328297D292E6361746368286675';
wwv_flow_imp.g_varchar2_table(375) := '6E6374696F6E28297B7D297D2C632E70726F746F747970652E736F756E644C6F73743D66756E6374696F6E2874297B74262674213D3D746869732E73747265616D7C7C746869732E736F756E645761726E65647C7C746869732E7374617465213D3D2272';
wwv_flow_imp.g_varchar2_table(376) := '65636F7264696E67222626746869732E7374617465213D3D22706175736564222626746869732E7374617465213D3D227265616479227C7C28746869732E736F756E645761726E65643D21302C746869732E736179286F28224E4F5F534F554E4422292C';
wwv_flow_imp.g_varchar2_table(377) := '227761726E22292C746869732E6669726528227761726E696E67222C7B726561736F6E3A226E6F736F756E64222C7365636F6E64733A746869732E7365636F6E64733F746869732E7365636F6E647328293A307D29297D2C632E70726F746F747970652E';
wwv_flow_imp.g_varchar2_table(378) := '6D6574657253746172743D66756E6374696F6E28297B76617220743D746869732C653D77696E646F772E417564696F436F6E746578747C7C77696E646F772E7765626B6974417564696F436F6E746578742C693D746869732E73747265616D2626746869';
wwv_flow_imp.g_varchar2_table(379) := '732E73747265616D2E676574417564696F547261636B7328295B305D2C6E3D692626692E67657453657474696E67733F692E67657453657474696E677328292E73616D706C65526174653A303B696628212821657C7C216929297B7472797B7472797B74';
wwv_flow_imp.g_varchar2_table(380) := '6869732E61633D6E65772065286E3F7B73616D706C65526174653A6E7D3A766F69642030297D63617463687B746869732E61633D6E657720657D746869732E61632E73746174653D3D3D2273757370656E646564222626746869732E61632E726573756D';
wwv_flow_imp.g_varchar2_table(381) := '6528292E63617463682866756E6374696F6E28297B7D293B76617220733D746869732E61632E6372656174654D6564696153747265616D536F7572636528746869732E73747265616D293B746869732E616E616C797365723D746869732E61632E637265';
wwv_flow_imp.g_varchar2_table(382) := '617465416E616C7973657228292C746869732E616E616C797365722E66667453697A653D313032342C732E636F6E6E65637428746869732E616E616C79736572297D63617463687B746869732E61633D6E756C6C3B72657475726E7D76617220723D7479';
wwv_flow_imp.g_varchar2_table(383) := '70656F6620746869732E616E616C797365722E676574466C6F617454696D65446F6D61696E446174613D3D2266756E6374696F6E222C753D723F6E657720466C6F61743332417272617928746869732E616E616C797365722E66667453697A65293A6E65';
wwv_flow_imp.g_varchar2_table(384) := '772055696E7438417272617928746869732E616E616C797365722E66667453697A65292C6C3D5B5D2C683D302C613D302C643D66756E6374696F6E2870297B696628742E616E616C79736572297B742E7261663D72657175657374416E696D6174696F6E';
wwv_flow_imp.g_varchar2_table(385) := '4672616D652864293B76617220673D302C452C523B6966287229666F7228742E616E616C797365722E676574466C6F617454696D65446F6D61696E446174612875292C453D303B453C752E6C656E6774683B452B2B29523D4D6174682E61627328755B45';
wwv_flow_imp.g_varchar2_table(386) := '5D292C523E67262628673D52293B656C736520666F7228742E616E616C797365722E6765744279746554696D65446F6D61696E446174612875292C453D303B453C752E6C656E6774683B452B2B29523D4D6174682E61627328755B455D2D313238292F31';
wwv_flow_imp.g_varchar2_table(387) := '32382C523E67262628673D52293B766172206B3D673E303F32302A4D6174682E6C6F672867292F4D6174682E4C4E31303A2D3130302C483D4D6174682E6D617828302C4D6174682E6D696E28312C286B2B3534292F343829293B696628613D4D6174682E';
wwv_flow_imp.g_varchar2_table(388) := '6D617828482C612A2E3835292C742E73746174653D3D3D227265636F7264696E67222626742E61632626742E61632E73746174653D3D3D2272756E6E696E67222626286B3E2D36303F742E68656172643D21303A21742E68656172642626742E7365636F';
wwv_flow_imp.g_varchar2_table(389) := '6E647328293E332E352626742E736F756E644C6F73742829292C2121742E68617328226C6576656C4D657465722229262628742E6C6576656C2E66697273744368696C642E7374796C652E77696474683D4D6174682E726F756E6428612A313030292B22';
wwv_flow_imp.g_varchar2_table(390) := '25222C742E6B696E643D3D3D22617564696F2229297B766172204F3D742E63616E7661732C493D4F2E636C69656E7457696474682C5F3D4F2E636C69656E744865696768742C503D77696E646F772E646576696365506978656C526174696F7C7C313B69';
wwv_flow_imp.g_varchar2_table(391) := '6628212821497C7C215F29297B284F2E7769647468213D3D4D6174682E726F756E6428492A50297C7C4F2E686569676874213D3D4D6174682E726F756E64285F2A5029292626284F2E77696474683D4D6174682E726F756E6428492A50292C4F2E686569';
wwv_flow_imp.g_varchar2_table(392) := '6768743D4D6174682E726F756E64285F2A5029293B76617220563D332C7A3D322C6D3D4D6174682E666C6F6F7228492F28562B7A29293B696628702D683E37302626742E7374617465213D3D227061757365642229666F7228683D702C6C2E7075736828';
wwv_flow_imp.g_varchar2_table(393) := '742E73746174653D3D3D227265636F7264696E67223F613A612A2E36293B6C2E6C656E6774683E6D3B296C2E736869667428293B76617220783D4F2E676574436F6E746578742822326422292C623D676574436F6D70757465645374796C6528742E726F';
wwv_flow_imp.g_varchar2_table(394) := '6F74293B782E7365745472616E73666F726D28502C302C302C502C302C30292C782E636C6561725265637428302C302C492C5F292C782E66696C6C5374796C653D742E73746174653D3D3D227265636F7264696E67223F622E67657450726F7065727479';
wwv_flow_imp.g_varchar2_table(395) := '56616C756528222D2D6D706C75732D7761766522292E7472696D28297C7C2223636231313030223A622E67657450726F706572747956616C756528222D2D6D706C75732D776176652D69646C6522292E7472696D28297C7C2223393939223B666F722876';
wwv_flow_imp.g_varchar2_table(396) := '617220763D303B763C6C2E6C656E6774683B762B2B297B76617220413D4D6174682E6D617828322C6C5B765D2A285F2D3429292C543D492D286C2E6C656E6774682D76292A28562B7A293B782E66696C6C5265637428542C285F2D41292F322C562C4129';
wwv_flow_imp.g_varchar2_table(397) := '7D7D7D7D7D3B746869732E7261663D72657175657374416E696D6174696F6E4672616D652864297D7D2C632E70726F746F747970652E6D6574657253746F703D66756E6374696F6E28297B746869732E726166262663616E63656C416E696D6174696F6E';
wwv_flow_imp.g_varchar2_table(398) := '4672616D6528746869732E726166292C746869732E7261663D6E756C6C2C746869732E616E616C797365723D6E756C6C2C746869732E61632626746869732E61632E636C6F736528292E63617463682866756E6374696F6E28297B7D292C746869732E61';
wwv_flow_imp.g_varchar2_table(399) := '633D6E756C6C2C746869732E6C6576656C2E66697273744368696C642E7374796C652E77696474683D2230227D2C632E70726F746F747970652E73747453746172743D66756E6374696F6E28297B76617220743D746869733B696628746869732E737474';
wwv_flow_imp.g_varchar2_table(400) := '546578743D22222C746869732E737474496E746572696D3D22222C746869732E7374744572726F723D6E756C6C2C746869732E73747446696E616C456C2E74657874436F6E74656E743D22222C746869732E737474496E746572696D456C2E7465787443';
wwv_flow_imp.g_varchar2_table(401) := '6F6E74656E743D22222C2121746869732E7472616E736372696265732829297B69662821746869732E5352297B746869732E736179286F28225354545F554E535550504F5254454422292C22696E666F22293B72657475726E7D76617220653D6E657720';
wwv_flow_imp.g_varchar2_table(402) := '746869732E53523B652E6C616E673D746869732E6C616E672C652E636F6E74696E756F75733D21302C652E696E746572696D526573756C74733D21302C652E6F6E726573756C743D66756E6374696F6E2869297B666F7228766172206E3D22222C733D69';
wwv_flow_imp.g_varchar2_table(403) := '2E726573756C74496E6465783B733C692E726573756C74732E6C656E6774683B732B2B297B76617220723D692E726573756C74735B735D5B305D2E7472616E7363726970743B692E726573756C74735B735D2E697346696E616C3F28723D722E7472696D';
wwv_flow_imp.g_varchar2_table(404) := '28292C72262628742E737474546578742B3D28742E737474546578743F2220223A2222292B7229293A6E2B3D727D742E737474496E746572696D3D6E2C742E73747446696E616C456C2E74657874436F6E74656E743D742E737474546578742B28742E73';
wwv_flow_imp.g_varchar2_table(405) := '74745465787426266E3F2220223A2222292C742E737474496E746572696D456C2E74657874436F6E74656E743D6E2C742E73796E6328297D2C652E6F6E6572726F723D66756E6374696F6E2869297B692E6572726F723D3D3D226E6F2D73706565636822';
wwv_flow_imp.g_varchar2_table(406) := '7C7C692E6572726F723D3D3D2261626F72746564227C7C28742E7374744572726F723D692E6572726F722C742E73747457616E7465643D21312C742E736179286F28225354545F4641494C4544222C692E6572726F72292C22696E666F2229297D2C652E';
wwv_flow_imp.g_varchar2_table(407) := '6F6E656E643D66756E6374696F6E28297B696628742E73747457616E7465642626742E73746174653D3D3D227265636F7264696E6722297472797B652E737461727428297D63617463687B7D656C736520742E737474446F6E652626742E737474446F6E';
wwv_flow_imp.g_varchar2_table(408) := '6528297D2C746869732E7374743D652C746869732E73747457616E7465643D21302C746869732E737474496E746572696D456C2E74657874436F6E74656E743D6F28225452414E5343524942494E4722293B7472797B652E737461727428297D63617463';
wwv_flow_imp.g_varchar2_table(409) := '687B7D746869732E73796E6328297D7D2C632E70726F746F747970652E73747450617573653D66756E6374696F6E2874297B696628212821746869732E7374747C7C746869732E7374744572726F7229297B746869732E73747457616E7465643D21743B';
wwv_flow_imp.g_varchar2_table(410) := '7472797B743F746869732E7374742E73746F7028293A746869732E7374742E737461727428297D63617463687B7D7D7D2C632E70726F746F747970652E73747446696E6973683D66756E6374696F6E28297B76617220743D746869732C653D746869732E';
wwv_flow_imp.g_varchar2_table(411) := '7374743B72657475726E20746869732E7374743D6E756C6C2C653F28746869732E73747457616E7465643D21312C6E65772050726F6D6973652866756E6374696F6E2869297B766172206E3D66756E6374696F6E28297B742E737474446F6E653D6E756C';
wwv_flow_imp.g_varchar2_table(412) := '6C2C6928297D3B742E737474446F6E653D6E2C73657454696D656F7574286E2C31353030293B7472797B652E73746F7028297D63617463687B6E28297D7D292E7468656E2866756E6374696F6E28297B652E6F6E656E643D652E6F6E726573756C743D65';
wwv_flow_imp.g_varchar2_table(413) := '2E6F6E6572726F723D6E756C6C3B7472797B652E61626F727428297D63617463687B7D742E737474496E746572696D262628742E737474546578742B3D28742E737474546578743F2220223A2222292B742E737474496E746572696D2E7472696D282929';
wwv_flow_imp.g_varchar2_table(414) := '2C742E737474496E746572696D3D22227D29293A50726F6D6973652E7265736F6C766528297D2C632E70726F746F747970652E73747441626F72743D66756E6374696F6E28297B696628746869732E737474297B746869732E73747457616E7465643D21';
wwv_flow_imp.g_varchar2_table(415) := '313B7472797B746869732E7374742E61626F727428297D63617463687B7D7D746869732E7374743D6E756C6C7D2C632E70726F746F747970652E73746172743D66756E6374696F6E28297B76617220743D746869733B746869732E64697361626C65647C';
wwv_flow_imp.g_varchar2_table(416) := '7C746869732E66756C6C28297C7C21746869732E737570706F727465647C7C28746869732E73746174653D3D3D2269646C65223F746869732E6F70656E28292E7468656E2866756E6374696F6E28297B742E63616D65726128293F742E73657453746174';
wwv_flow_imp.g_varchar2_table(417) := '652822726561647922293A742E626567696E28297D292E63617463682866756E6374696F6E28297B7D293A746869732E73746174653D3D3D22726561647922262628746869732E6B696E643D3D3D22696D616765223F746869732E636170747572652829';
wwv_flow_imp.g_varchar2_table(418) := '3A746869732E626567696E282929297D2C632E70726F746F747970652E636170747572653D66756E6374696F6E28297B76617220743D746869732C653D746869732E766964656F2C693D652E766964656F57696474682C6E3D652E766964656F48656967';
wwv_flow_imp.g_varchar2_table(419) := '68743B6966282128746869732E7374617465213D3D227265616479227C7C21697C7C216E29297B76617220733D777428692C6E293B732E676574436F6E746578742822326422292E64726177496D61676528652C302C302C692C6E292C746869732E7374';
wwv_flow_imp.g_varchar2_table(420) := '6167652E636C6173734C6973742E616464282269732D666C61736822292C73657454696D656F75742866756E6374696F6E28297B742E73746167652E636C6173734C6973742E72656D6F7665282269732D666C61736822297D2C323030292C746869732E';
wwv_flow_imp.g_varchar2_table(421) := '7365745374617465282273746F7070696E6722292C746869732E726177426C6F623D6E756C6C2C577428732C22696D6167652F6A706567222C2E3935292E7468656E2866756E6374696F6E2872297B742E72656C6561736528292C742E75706C6F61644E';
wwv_flow_imp.g_varchar2_table(422) := '616D653D6E756C6C2C742E70656E64696E674E616D653D6E756C6C2C742E66697265282263617074757265222C7B77696474683A692C6865696768743A6E7D292C742E74616B6528722C6E756C6C2C2222297D297D7D2C632E70726F746F747970652E62';
wwv_flow_imp.g_varchar2_table(423) := '6567696E3D66756E6374696F6E28297B76617220743D746869733B696628746869732E6861732822636F756E74646F776E2229297B76617220653D333B746869732E73657453746174652822636F756E74646F776E22292C746869732E636F756E74646F';
wwv_flow_imp.g_varchar2_table(424) := '776E2E74657874436F6E74656E743D652C746869732E636454696D65723D736574496E74657276616C2866756E6374696F6E28297B696628652D2D2C653E30297B742E636F756E74646F776E2E74657874436F6E74656E743D653B72657475726E7D636C';
wwv_flow_imp.g_varchar2_table(425) := '656172496E74657276616C28742E636454696D6572292C742E636F756E74646F776E2E74657874436F6E74656E743D22222C742E73746174653D3D3D22636F756E74646F776E222626742E7265636F726428297D2C316533297D656C736520746869732E';
wwv_flow_imp.g_varchar2_table(426) := '7265636F726428297D2C632E70726F746F747970652E7265636F72643D66756E6374696F6E28297B76617220743D746869732C653D746869732E7175616C69747928292C693D7B7D2C6E3D427428746869732E6B696E642C746869732E6366672E666F72';
wwv_flow_imp.g_varchar2_table(427) := '6D6174292C733D746869732E617564696F4B627073286E293B6E262628692E6D696D65547970653D6E292C746869732E77697468536F756E642829262628692E617564696F426974735065725365636F6E643D732A316533292C746869732E6B696E643D';
wwv_flow_imp.g_varchar2_table(428) := '3D3D22766964656F22262628692E766964656F426974735065725365636F6E643D652E766964656F4B6270732A316533292C746869732E68656172643D21312C746869732E736F756E645761726E65643D21313B7472797B746869732E7265633D6E6577';
wwv_flow_imp.g_varchar2_table(429) := '204D656469615265636F7264657228746869732E73747265616D2C69297D63617463687B7472797B746869732E7265633D6E6577204D656469615265636F7264657228746869732E73747265616D297D63617463687B746869732E72656C656173652829';
wwv_flow_imp.g_varchar2_table(430) := '2C746869732E7365745374617465282269646C6522292C746869732E736179286F28224E4F545F535550504F5254454422292C226572726F7222293B72657475726E7D7D746869732E6368756E6B733D5B5D2C746869732E62797465733D302C74686973';
wwv_flow_imp.g_varchar2_table(431) := '2E6C6173744368756E6B3D302C746869732E6368756E6B41743D302C746869732E6270733D2828746869732E77697468536F756E6428293F733A30292B28746869732E6B696E643D3D3D22766964656F223F652E766964656F4B6270733A3029292A3165';
wwv_flow_imp.g_varchar2_table(432) := '332F382C746869732E656C61707365643D302C746869732E73696E63653D446174652E6E6F7728292C746869732E7761726E65643D21312C746869732E73746F70526561736F6E3D6E756C6C2C746869732E7265632E6F6E64617461617661696C61626C';
wwv_flow_imp.g_varchar2_table(433) := '653D66756E6374696F6E2872297B722E646174612626722E646174612E73697A65262628742E6368756E6B732E7075736828722E64617461292C742E62797465732B3D722E646174612E73697A652C742E6C6173744368756E6B3D722E646174612E7369';
wwv_flow_imp.g_varchar2_table(434) := '7A652C742E6368756E6B41743D742E7365636F6E647328292C742E636865636B2829297D2C746869732E7265632E6F6E73746F703D66756E6374696F6E28297B742E66696E697368656428297D2C746869732E7265632E6F6E6572726F723D66756E6374';
wwv_flow_imp.g_varchar2_table(435) := '696F6E2872297B742E73617928722E6572726F722626722E6572726F722E6D6573736167657C7C6F28224E4F545F535550504F5254454422292C226572726F7222297D2C746869732E7265632E737461727428316533292C746869732E73617928222229';
wwv_flow_imp.g_varchar2_table(436) := '2C746869732E736574537461746528227265636F7264696E6722292C746869732E737474537461727428292C746869732E7469636B3D736574496E74657276616C2866756E6374696F6E28297B742E636865636B28297D2C323530292C746869732E6368';
wwv_flow_imp.g_varchar2_table(437) := '65636B28292C746869732E6669726528227374617274222C7B6B696E643A746869732E6B696E642C6D696D65547970653A746869732E7265632E6D696D65547970657D297D2C632E70726F746F747970652E7365636F6E64733D66756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(438) := '7B72657475726E28746869732E656C61707365642B28746869732E73746174653D3D3D227265636F7264696E67223F446174652E6E6F7728292D746869732E73696E63653A3029292F3165337D2C632E70726F746F747970652E636865636B3D66756E63';
wwv_flow_imp.g_varchar2_table(439) := '74696F6E28297B6966282128746869732E7374617465213D3D227265636F7264696E67222626746869732E7374617465213D3D227061757365642229297B76617220743D746869732E6366672C653D746869732E7365636F6E647328292C693D4D617468';
wwv_flow_imp.g_varchar2_table(440) := '2E6D617828302C652D746869732E6368756E6B4174292C6E3D746869732E62797465732B692A746869732E6270732C733D742E6D617842797465732A28693E312E353F2E39343A31292C723D6E2F732C753D742E6D61784475726174696F6E3F652F742E';
wwv_flow_imp.g_varchar2_table(441) := '6D61784475726174696F6E3A302C6C3D4D6174682E6D696E28312C4D6174682E6D617828722C7529292C683D28742E7761726E5063747C7C3830292F3130302C613D653E323F6E2F653A302C643D613F28732D6E292F613A303B742E6D61784475726174';
wwv_flow_imp.g_varchar2_table(442) := '696F6E262628643D643F4D6174682E6D696E28642C742E6D61784475726174696F6E2D65293A742E6D61784475726174696F6E2D65292C746869732E74696D65722E74657874436F6E74656E743D582865292C746869732E6D6574657246696C6C2E7374';
wwv_flow_imp.g_varchar2_table(443) := '796C652E77696474683D286C2A313030292E746F46697865642831292B2225222C746869732E6D657465724261722E7365744174747269627574652822617269612D76616C75656E6F77222C4D6174682E726F756E64286C2A31303029292C746869732E';
wwv_flow_imp.g_varchar2_table(444) := '6D657465722E636C6173734C6973742E746F67676C65282269732D7761726E222C6C3E3D68292C746869732E6D65746572546578742E74657874436F6E74656E743D643E302626653E323F6F28224D45544552222C582864292C44286E292C4428742E6D';
wwv_flow_imp.g_varchar2_table(445) := '6178427974657329293A6F28224F46222C44286E292C4428742E6D6178427974657329292C21746869732E7761726E656426266C3E3D682626683C31262628746869732E7761726E65643D21302C746869732E73617928753E723F6F28225741524E5F54';
wwv_flow_imp.g_varchar2_table(446) := '494D45222C582865292C5828742E6D61784475726174696F6E29293A6F28225741524E5F53495A45222C44286E292C4428742E6D6178427974657329292C227761726E22292C6E6176696761746F722E7669627261746526266E6176696761746F722E76';
wwv_flow_imp.g_varchar2_table(447) := '69627261746528323030292C746869732E6669726528227761726E696E67222C7B62797465733A6E2C7365636F6E64733A652C6D617842797465733A742E6D617842797465732C6D61784475726174696F6E3A742E6D61784475726174696F6E7D29293B';
wwv_flow_imp.g_varchar2_table(448) := '76617220703D4D6174682E6D617828746869732E6C6173744368756E6B2C61292A312E353B746869732E73746174653D3D3D227265636F7264696E672226266E2B703E3D733F746869732E73746F70282273697A6522293A746869732E73746174653D3D';
wwv_flow_imp.g_varchar2_table(449) := '3D227265636F7264696E67222626742E6D61784475726174696F6E2626653E3D742E6D61784475726174696F6E2626746869732E73746F7028226475726174696F6E22297D7D2C632E70726F746F747970652E746F67676C6550617573653D66756E6374';
wwv_flow_imp.g_varchar2_table(450) := '696F6E28297B746869732E73746174653D3D3D22706175736564223F746869732E726573756D6528293A746869732E706175736528297D2C632E70726F746F747970652E70617573653D66756E6374696F6E28297B746869732E7374617465213D3D2272';
wwv_flow_imp.g_varchar2_table(451) := '65636F7264696E67227C7C21746869732E7265637C7C28746869732E7265632E706175736528292C746869732E656C61707365642B3D446174652E6E6F7728292D746869732E73696E63652C746869732E7374745061757365282130292C746869732E73';
wwv_flow_imp.g_varchar2_table(452) := '65745374617465282270617573656422292C746869732E6669726528227061757365222C7B7365636F6E64733A746869732E7365636F6E647328297D29297D2C632E70726F746F747970652E726573756D653D66756E6374696F6E28297B746869732E73';
wwv_flow_imp.g_varchar2_table(453) := '74617465213D3D22706175736564227C7C21746869732E7265637C7C28746869732E7265632E726573756D6528292C746869732E73696E63653D446174652E6E6F7728292C746869732E736574537461746528227265636F7264696E6722292C74686973';
wwv_flow_imp.g_varchar2_table(454) := '2E7374745061757365282131292C746869732E666972652822726573756D65222C7B7365636F6E64733A746869732E7365636F6E647328297D29297D2C632E70726F746F747970652E73746F703D66756E6374696F6E2874297B696628746869732E7374';
wwv_flow_imp.g_varchar2_table(455) := '6174653D3D3D226F70656E696E6722297B746869732E63616E63656C6C65643D21302C746869732E72656C6561736528292C746869732E7365745374617465282269646C6522293B72657475726E7D696628746869732E73746174653D3D3D22636F756E';
wwv_flow_imp.g_varchar2_table(456) := '74646F776E22297B636C656172496E74657276616C28746869732E636454696D6572292C746869732E636F756E74646F776E2E74657874436F6E74656E743D22222C746869732E72656C6561736528292C746869732E7365745374617465282269646C65';
wwv_flow_imp.g_varchar2_table(457) := '22293B72657475726E7D696628212821746869732E7265637C7C746869732E7374617465213D3D227265636F7264696E67222626746869732E7374617465213D3D227061757365642229297B746869732E73746174653D3D3D227265636F7264696E6722';
wwv_flow_imp.g_varchar2_table(458) := '262628746869732E656C61707365642B3D446174652E6E6F7728292D746869732E73696E6365292C746869732E73746F70526561736F6E3D747970656F6620743D3D22737472696E67223F743A6E756C6C2C636C656172496E74657276616C2874686973';
wwv_flow_imp.g_varchar2_table(459) := '2E7469636B292C746869732E7365745374617465282273746F7070696E6722293B7472797B746869732E7265632E73746F7028297D63617463687B746869732E66696E697368656428297D7D7D2C632E70726F746F747970652E66696E69736865643D66';
wwv_flow_imp.g_varchar2_table(460) := '756E6374696F6E28297B76617220743D746869732C653D746869732E6366672C693D28746869732E7265632626746869732E7265632E6D696D65547970657C7C746869732E6368756E6B735B305D2626746869732E6368756E6B735B305D2E747970657C';
wwv_flow_imp.g_varchar2_table(461) := '7C746869732E6B696E642B222F7765626D22292E73706C697428223B22295B305D2C6E3D6E657720426C6F6228746869732E6368756E6B732C7B747970653A697D292C733D746869732E656C61707365642F3165333B746869732E72656C656173652829';
wwv_flow_imp.g_varchar2_table(462) := '2C746869732E6368756E6B733D5B5D2C746869732E7265633D6E756C6C2C746869732E73746F70526561736F6E3D3D3D2273697A65223F28746869732E736179286F282253544F505045445F53495A45222C4428652E6D6178427974657329292C227761';
wwv_flow_imp.g_varchar2_table(463) := '726E22292C746869732E6669726528226C696D6974222C7B726561736F6E3A2273697A65222C62797465733A6E2E73697A652C7365636F6E64733A737D29293A746869732E73746F70526561736F6E3D3D3D226475726174696F6E223F28746869732E73';
wwv_flow_imp.g_varchar2_table(464) := '6179286F282253544F505045445F54494D45222C5828652E6D61784475726174696F6E29292C227761726E22292C746869732E6669726528226C696D6974222C7B726561736F6E3A226475726174696F6E222C62797465733A6E2E73697A652C7365636F';
wwv_flow_imp.g_varchar2_table(465) := '6E64733A737D29293A746869732E73746F70526561736F6E213D3D2264657669636522262621746869732E7374744572726F722626746869732E736179282222292C50726F6D6973652E616C6C285B7565286E2C732A316533292C746869732E73747446';
wwv_flow_imp.g_varchar2_table(466) := '696E69736828295D292E7468656E2866756E6374696F6E2872297B76617220753D725B305D3B69662866742822706C61796261636B22292C742E726177426C6F623D75213D3D6E3F6E3A6E756C6C2C617065782E64656275672626617065782E64656275';
wwv_flow_imp.g_varchar2_table(467) := '672E696E666F28224D65646961506C7573222C742E6366672E6974656D2C692C227265636F72646564222C6E2E73697A652C227265706169726564222C75213D3D6E3F752E73697A653A226E6F22292C742E66697265282273746F70222C7B6279746573';
wwv_flow_imp.g_varchar2_table(468) := '3A752E73697A652C7365636F6E64733A732C6D696D65547970653A697D292C21752E73697A65297B742E7365745374617465282269646C6522293B72657475726E7D742E746F6F4269673D752E73697A653E652E6D617842797465732A28652E616C6C6F';
wwv_flow_imp.g_varchar2_table(469) := '77616E63657C7C31292C742E746F6F4269672626742E736179286F2822544F4F5F4C415247455F4B454550222C4428752E73697A65292C4428652E6D6178427974657329292C226572726F7222292C742E74616B6528752C732C742E7472616E73637269';
wwv_flow_imp.g_varchar2_table(470) := '62657328293F742E737474546578743A22222C742E746F6F426967297D297D2C632E70726F746F747970652E74616B653D66756E6374696F6E28742C652C692C6E297B76617220733D746869733B696628746869732E70656E64696E67426C6F623D742C';
wwv_flow_imp.g_varchar2_table(471) := '746869732E70656E64696E675365633D652C746869732E6661696C65643D21312C746869732E726576696577546578742E76616C75653D28697C7C2222292E736C69636528302C5474292C28742E747970657C7C2222292E696E6465784F662822696D61';
wwv_flow_imp.g_varchar2_table(472) := '67652F22293D3D3D30297B746869732E6B696E643D22696D616765222C746869732E65644C6F61642874292E7468656E2866756E6374696F6E28297B732E68617328227072657669657722297C7C732E746F6F6C732E6C656E6774687C7C6E3F732E7368';
wwv_flow_imp.g_varchar2_table(473) := '6F7752657669657728293A732E61636365707428297D292E63617463682866756E6374696F6E2872297B732E65643D6E756C6C2C732E70656E64696E67426C6F623D6E756C6C2C732E7365745374617465282269646C6522292C732E736179286F282250';
wwv_flow_imp.g_varchar2_table(474) := '484F544F5F4641494C4544222C722626722E6D6573736167657C7C2222292C226572726F7222297D293B72657475726E7D746869732E65643D6E756C6C2C746869732E68617328227072657669657722297C7C6E3F746869732E73686F77526576696577';
wwv_flow_imp.g_varchar2_table(475) := '28293A746869732E61636365707428297D2C632E70726F746F747970652E66696C654E616D653D66756E6374696F6E28742C65297B76617220693D6E657720446174652C6E3D66756E6374696F6E2872297B72657475726E20537472696E672872292E70';
wwv_flow_imp.g_varchar2_table(476) := '6164537461727428322C223022297D2C733D692E67657446756C6C5965617228292B6E28692E6765744D6F6E746828292B31292B6E28692E676574446174652829292B222D222B6E28692E676574486F7572732829292B6E28692E6765744D696E757465';
wwv_flow_imp.g_varchar2_table(477) := '732829292B6E28692E6765745365636F6E64732829293B72657475726E28746869732E6366672E66696C654E616D657C7C22234954454D232D2354494D455354414D502322292E7265706C616365282F234954454D232F672C746869732E6366672E6974';
wwv_flow_imp.g_varchar2_table(478) := '656D2E746F4C6F776572436173652829292E7265706C616365282F2354494D455354414D50232F672C73292E7265706C616365282F234B494E44232F672C65292E7265706C616365282F234E232F672C746869732E6974656D732E6C656E6774682B3129';
wwv_flow_imp.g_varchar2_table(479) := '2E7265706C616365282F5B5E5C772E5C2D205D2B2F672C225F22292B222E222B67742874297D2C632E70726F746F747970652E73686F775265766965773D66756E6374696F6E28297B696628746869732E6564297B746869732E70656E64696E674E616D';
wwv_flow_imp.g_varchar2_table(480) := '653D746869732E70656E64696E674E616D657C7C28746869732E75706C6F61644E616D653F746869732E75706C6F61644E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C2222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C225F';
wwv_flow_imp.g_varchar2_table(481) := '22293A6E756C6C292C746869732E61446F776E6C6F61642E687265663D2223222C746869732E7365745374617465282272657669657722292C746869732E73617665447261667428292C746869732E656452656E64657228292C28746869732E746F6F42';
wwv_flow_imp.g_varchar2_table(482) := '69673F746869732E61446F776E6C6F61643A746869732E62557365292E666F63757328293B72657475726E7D76617220743D746869732C653D746869732E70656E64696E67426C6F622C693D652E747970652E696E6465784F662822766964656F22293D';
wwv_flow_imp.g_varchar2_table(483) := '3D3D303F22766964656F223A22617564696F222C6E3D6628692C226D706C75732D6D65646961222C7B636F6E74726F6C733A21302C706C617973696E6C696E653A693D3D3D22766964656F223F21303A6E756C6C2C7072656C6F61643A226D6574616461';
wwv_flow_imp.g_varchar2_table(484) := '7461227D293B746869732E72657669657755726C262655524C2E7265766F6B654F626A65637455524C28746869732E72657669657755726C292C746869732E72657669657755726C3D55524C2E6372656174654F626A65637455524C2865292C6E2E6164';
wwv_flow_imp.g_varchar2_table(485) := '644576656E744C697374656E65722822706C6179222C66756E6374696F6E28297B66742822706C61796261636B22297D292C6E2E6164644576656E744C697374656E657228226572726F72222C66756E6374696F6E28297B742E706C61794572726F7228';
wwv_flow_imp.g_varchar2_table(486) := '6E2C65297D292C6B74286E292C6E2E7372633D746869732E72657669657755726C2C746869732E706C617965722E696E6E657248544D4C3D22222C746869732E706C617965722E617070656E644368696C64286E292C746869732E7265766965774D6574';
wwv_flow_imp.g_varchar2_table(487) := '612E74657874436F6E74656E743D28746869732E70656E64696E675365633F5828746869732E70656E64696E67536563292B22205C78423720223A2222292B4428652E73697A65292C746869732E70656E64696E674E616D653D746869732E70656E6469';
wwv_flow_imp.g_varchar2_table(488) := '6E674E616D657C7C28746869732E75706C6F61644E616D653F746869732E75706C6F61644E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C2222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C225F22292B222E222B677428652E';
wwv_flow_imp.g_varchar2_table(489) := '74797065293A746869732E66696C654E616D6528652E747970652C6929292C746869732E61446F776E6C6F61642E687265663D746869732E72657669657755726C2C746869732E61446F776E6C6F61642E7365744174747269627574652822646F776E6C';
wwv_flow_imp.g_varchar2_table(490) := '6F6164222C746869732E70656E64696E674E616D65292C746869732E7365745374617465282272657669657722292C746869732E73617665447261667428292C28746869732E746F6F4269673F746869732E61446F776E6C6F61643A746869732E625573';
wwv_flow_imp.g_varchar2_table(491) := '65292E666F63757328297D2C632E70726F746F747970652E706C61794572726F723D66756E6374696F6E28742C65297B76617220693D742E6572726F723F742E6572726F722E636F64653A302C6E3D742E6572726F722626742E6572726F722E6D657373';
wwv_flow_imp.g_varchar2_table(492) := '6167657C7C22223B696628617065782E64656275672626617065782E64656275672E7761726E28224D65646961506C7573222C746869732E6366672E6974656D2C227265766965772063616E6E6F7420706C6179222C652E747970652C652E73697A652C';
wwv_flow_imp.g_varchar2_table(493) := '22636F6465222C692C6E292C212865213D3D746869732E70656E64696E67426C6F627C7C746869732E7374617465213D3D227265766965772229297B696628746869732E726177426C6F622626746869732E726177426C6F62213D3D65297B746869732E';
wwv_flow_imp.g_varchar2_table(494) := '70656E64696E67426C6F623D746869732E726177426C6F622C746869732E726177426C6F623D6E756C6C2C746869732E73686F7752657669657728293B72657475726E7D746869732E736179286F2822504C41595F4641494C4544222C2228222B286E7C';
wwv_flow_imp.g_varchar2_table(495) := '7C22636F646520222B69292B222922292C227761726E22297D7D2C632E70726F746F747970652E7361766544726166743D66756E6374696F6E28297B21746869732E70656E64696E67426C6F627C7C746869732E746F6F4269677C7C4F742E7075742874';
wwv_flow_imp.g_varchar2_table(496) := '6869732E64726166744B65792C7B626C6F623A746869732E70656E64696E67426C6F622C7261773A746869732E726177426C6F627C7C6E756C6C2C747970653A746869732E70656E64696E67426C6F622E747970652C7365633A746869732E70656E6469';
wwv_flow_imp.g_varchar2_table(497) := '6E675365632C6E616D653A746869732E70656E64696E674E616D652C7472616E7363726970743A746869732E726576696577546578742E76616C75652C61743A446174652E6E6F7728297D297D2C632E70726F746F747970652E64726F7044726166743D';
wwv_flow_imp.g_varchar2_table(498) := '66756E6374696F6E28297B4F742E64656C28746869732E64726166744B6579297D2C632E70726F746F747970652E7265636F7665723D66756E6374696F6E28297B76617220743D746869732C653D6E756C6C3B7472797B653D73657373696F6E53746F72';
wwv_flow_imp.g_varchar2_table(499) := '6167652E6765744974656D28226D706C75732D6E6F64726166743A222B746869732E64726166744B6579292C73657373696F6E53746F726167652E72656D6F76654974656D28226D706C75732D6E6F64726166743A222B746869732E64726166744B6579';
wwv_flow_imp.g_varchar2_table(500) := '297D63617463687B7D69662865297B746869732E64726F70447261667428293B72657475726E7D4F742E67657428746869732E64726166744B6579292E7468656E2866756E6374696F6E2869297B696628212821697C7C21692E626C6F627C7C742E7374';
wwv_flow_imp.g_varchar2_table(501) := '617465213D3D2269646C65227C7C742E66756C6C282929297B696628446174652E6E6F7728292D692E61743E24742A3836346535297B742E64726F70447261667428293B72657475726E7D766172206E3D66756E6374696F6E2873297B72657475726E20';
wwv_flow_imp.g_varchar2_table(502) := '733F732E617272617942756666657228292E7468656E2866756E6374696F6E2872297B72657475726E206E657720426C6F62285B725D2C7B747970653A732E747970657C7C692E747970657D297D293A50726F6D6973652E7265736F6C7665286E756C6C';
wwv_flow_imp.g_varchar2_table(503) := '297D3B50726F6D6973652E616C6C285B6E28692E626C6F62292C6E28692E726177295D292E7468656E2866756E6374696F6E2873297B742E73746174653D3D3D2269646C6522262628742E70656E64696E674E616D653D692E6E616D652C742E72617742';
wwv_flow_imp.g_varchar2_table(504) := '6C6F623D735B315D2C742E74616B6528735B305D2C692E7365632C692E7472616E7363726970742C2130292C742E736179286F28225245434F564552454422292C22696E666F2229297D292E63617463682866756E6374696F6E28297B742E64726F7044';
wwv_flow_imp.g_varchar2_table(505) := '7261667428297D297D7D297D2C632E70726F746F747970652E636C6561725265766965773D66756E6374696F6E28297B76617220743D746869732E706C617965722E717565727953656C6563746F722822617564696F2C766964656F22293B742626742E';
wwv_flow_imp.g_varchar2_table(506) := '706175736528292C746869732E706C617965722E696E6E657248544D4C3D22222C746869732E72657669657755726C262655524C2E7265766F6B654F626A65637455524C28746869732E72657669657755726C292C746869732E646C55726C262655524C';
wwv_flow_imp.g_varchar2_table(507) := '2E7265766F6B654F626A65637455524C28746869732E646C55726C292C746869732E72657669657755726C3D746869732E646C55726C3D6E756C6C2C746869732E65643D6E756C6C2C746869732E656443616368653D746869732E6564427573793D6E75';
wwv_flow_imp.g_varchar2_table(508) := '6C6C7D2C632E70726F746F747970652E70686F746F4E616D653D66756E6374696F6E2874297B72657475726E20746869732E70656E64696E674E616D653F746869732E70656E64696E674E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C2222';
wwv_flow_imp.g_varchar2_table(509) := '292B222E222B67742874293A746869732E66696C654E616D6528742C22696D61676522297D2C632E70726F746F747970652E646973636172643D66756E6374696F6E2874297B76617220653D746869732C693D66756E6374696F6E28297B652E636C6561';
wwv_flow_imp.g_varchar2_table(510) := '7252657669657728292C652E70656E64696E67426C6F623D6E756C6C2C652E726177426C6F623D6E756C6C2C652E70656E64696E674E616D653D6E756C6C2C652E746F6F4269673D21312C652E6661696C65643D21312C652E726576696577546578742E';
wwv_flow_imp.g_varchar2_table(511) := '76616C75653D22222C652E64726F70447261667428292C652E736179282222292C652E7365745374617465282269646C6522292C652E6669726528226469736361726422292C742626652E737461727428297D3B746869732E73746174653D3D3D227265';
wwv_flow_imp.g_varchar2_table(512) := '766965772226262821742626746869732E6861732822636F6E6669726D44656C65746522293F617065782E6D6573736167652E636F6E6669726D286F2822434F4E4649524D5F4449534341524422292C66756E6374696F6E286E297B6E26266928297D29';
wwv_flow_imp.g_varchar2_table(513) := '3A692829297D2C632E70726F746F747970652E75736546696C653D66756E6374696F6E2874297B76617220653D746869732C693D746869732E6366672C6E3D28742E747970657C7C2222292E746F4C6F7765724361736528292C733D6E2E73706C697428';
wwv_flow_imp.g_varchar2_table(514) := '222F22295B305D3B696628746869732E6B696E64732E696E6465784F662873293C30297B746869732E736179286F282246494C455F57524F4E475F5459504522292C226572726F7222293B72657475726E7D69662873213D3D22696D616765222626742E';
wwv_flow_imp.g_varchar2_table(515) := '73697A653E692E6D61784279746573297B746869732E736179286F282246494C455F544F4F5F4C41524745222C4428742E73697A65292C4428692E6D6178427974657329292C226572726F7222293B72657475726E7D696628746869732E736179282222';
wwv_flow_imp.g_varchar2_table(516) := '292C746869732E6B696E643D732C746869732E726177426C6F623D6E756C6C2C733D3D3D22696D61676522297B746869732E75706C6F61644E616D653D742E6E616D652C746869732E70656E64696E674E616D653D6E756C6C2C746869732E74616B6528';
wwv_flow_imp.g_varchar2_table(517) := '742C6E756C6C2C2222293B72657475726E7D61652874292E7468656E2866756E6374696F6E2872297B652E75706C6F61644E616D653D742E6E616D652C652E70656E64696E674E616D653D6E756C6C2C652E74616B6528742C722C2222297D297D3B7661';
wwv_flow_imp.g_varchar2_table(518) := '722053743D7B22313A31223A312C22343A33223A342F332C22333A34223A332F342C2231363A39223A31362F392C22393A3136223A392F31367D2C50743D5B2223653533393335222C2223666464383335222C2223666666666666222C22233231323132';
wwv_flow_imp.g_varchar2_table(519) := '31225D3B632E70726F746F747970652E6275696C64456469746F723D66756E6374696F6E2874297B76617220653D746869732C693D746869732E6366672C6E3D746869732E746F6F6C732C733D66756E6374696F6E2861297B72657475726E206E2E696E';
wwv_flow_imp.g_varchar2_table(520) := '6465784F662861293E3D307D2C723D66756E6374696F6E28612C642C70297B72657475726E204728226D706C75732D62746E2D2D67686F737420222B612C642C702C21302C74297D2C753D53745B692E63726F70526174696F5D3B746869732E65644361';
wwv_flow_imp.g_varchar2_table(521) := '6E7661733D66282263616E766173222C226D706C75732D65642D63616E76617322292C746869732E656443726F703D662822646976222C226D706C75732D65642D63726F70222C7B746162696E6465783A2230222C726F6C653A2267726F7570222C2261';
wwv_flow_imp.g_varchar2_table(522) := '7269612D6C6162656C223A6F282243524F5022297D2C5B226E77222C226E222C226E65222C2265222C227365222C2273222C227377222C2277225D2E6D61702866756E6374696F6E2861297B72657475726E206628227370616E222C226D706C75732D65';
wwv_flow_imp.g_varchar2_table(523) := '642D68206D706C75732D65642D682D2D222B612C7B22646174612D68223A617D297D29292C746869732E6564577261703D662822646976222C226D706C75732D65642D77726170222C6E756C6C2C5B746869732E656443616E7661732C746869732E6564';
wwv_flow_imp.g_varchar2_table(524) := '43726F705D292C746869732E62526F744C3D7228226D706C75732D652D726F746C222C2266612D726F746174652D6C656674222C6F2822524F544154455F4C4546542229292C746869732E62526F74523D7228226D706C75732D652D726F7472222C2266';
wwv_flow_imp.g_varchar2_table(525) := '612D726F746174652D7269676874222C6F2822524F544154455F52494748542229292C746869732E62466C69703D7228226D706C75732D652D666C6970222C2266612D6172726F77732D68222C6F2822464C49502229292C746869732E6241646A757374';
wwv_flow_imp.g_varchar2_table(526) := '3D7228226D706C75732D652D61646A757374222C2266612D736C6964657273222C6F282241444A5553542229292C746869732E62477261793D7228226D706C75732D652D67726179222C2266612D61646A757374222C6F2822475241595343414C452229';
wwv_flow_imp.g_varchar2_table(527) := '292C746869732E62447261773D7228226D706C75732D652D64726177222C2266612D70656E63696C222C6F2822445241572229292C746869732E62556E646F3D7228226D706C75732D652D756E646F222C2266612D657261736572222C6F2822554E444F';
wwv_flow_imp.g_varchar2_table(528) := '2229292C746869732E6252657365743D4728226D706C75732D62746E2D2D67686F7374206D706C75732D652D7265736574222C2266612D72656672657368222C6F2822524553455422292C21312C74292C746869732E6564526174696F3D66282273656C';
wwv_flow_imp.g_varchar2_table(529) := '656374222C226D706C75732D65642D73656C656374206D706C75732D652D726174696F222C7B22617269612D6C6162656C223A6F282243524F5022292C7469746C653A6F282243524F5022297D2C5B5B2246524545222C6F282243524F505F4652454522';
wwv_flow_imp.g_varchar2_table(530) := '295D2C5B22313A31222C22313A31225D2C5B22343A33222C22343A33225D2C5B22333A34222C22333A34225D2C5B2231363A39222C2231363A39225D2C5B22393A3136222C22393A3136225D2C5B22414C4C222C6F282243524F505F414C4C22295D5D2E';
wwv_flow_imp.g_varchar2_table(531) := '6D61702866756E6374696F6E2861297B72657475726E206628226F7074696F6E222C6E756C6C2C7B76616C75653A615B305D2C746578743A615B315D7D297D29293B766172206C3D692E696D6167654D6178536964657C7C313932303B746869732E6564';
wwv_flow_imp.g_varchar2_table(532) := '53697A653D66282273656C656374222C226D706C75732D65642D73656C656374206D706C75732D652D73697A65222C7B22617269612D6C6162656C223A6F282253495A4522292C7469746C653A6F282253495A4522297D2C5B6C5D2E636F6E636174285B';
wwv_flow_imp.g_varchar2_table(533) := '313630302C313238302C313032342C3830302C3634305D2E66696C7465722866756E6374696F6E2861297B72657475726E20613C6C7D29292E6D61702866756E6374696F6E28612C64297B72657475726E206628226F7074696F6E222C6E756C6C2C7B76';
wwv_flow_imp.g_varchar2_table(534) := '616C75653A612C746578743A6F28643F2253495A455F5058223A2253495A455F46554C4C222C61297D297D29292C746869732E6564436F6C6F7572733D6628227370616E222C226D706C75732D65642D636F6C6F757273222C7B726F6C653A2267726F75';
wwv_flow_imp.g_varchar2_table(535) := '70222C22617269612D6C6162656C223A6F28224452415722297D2C50742E6D61702866756E6374696F6E2861297B76617220643D662822627574746F6E222C226D706C75732D65642D636F6C6F7572222C7B747970653A22627574746F6E222C22617269';
wwv_flow_imp.g_varchar2_table(536) := '612D6C6162656C223A612C7469746C653A612C22617269612D70726573736564223A537472696E6728613D3D3D50745B305D297D293B72657475726E20642E7374796C652E6261636B67726F756E643D612C642E6164644576656E744C697374656E6572';
wwv_flow_imp.g_varchar2_table(537) := '2822636C69636B222C66756E6374696F6E28297B652E65642E636F6C6F75723D612C41727261792E70726F746F747970652E666F72456163682E63616C6C28652E6564436F6C6F7572732E6368696C6472656E2C66756E6374696F6E2870297B702E7365';
wwv_flow_imp.g_varchar2_table(538) := '744174747269627574652822617269612D70726573736564222C537472696E6728703D3D3D6429297D297D292C647D29292C746869732E6564546F6F6C733D662822646976222C226D706C75732D65642D746F6F6C73222C7B726F6C653A22746F6F6C62';
wwv_flow_imp.g_varchar2_table(539) := '6172222C22617269612D6C6162656C223A6F282241444A55535422297D2C5B73282263726F702229262621753F746869732E6564526174696F3A6E756C6C2C732822726F7461746522293F746869732E62526F744C3A6E756C6C2C732822726F74617465';
wwv_flow_imp.g_varchar2_table(540) := '22293F746869732E62526F74523A6E756C6C2C732822666C697022293F746869732E62466C69703A6E756C6C2C73282261646A75737422293F746869732E6241646A7573743A6E756C6C2C73282261646A75737422293F746869732E62477261793A6E75';
wwv_flow_imp.g_varchar2_table(541) := '6C6C2C7328226472617722293F746869732E62447261773A6E756C6C2C7328226472617722293F746869732E6564436F6C6F7572733A6E756C6C2C7328226472617722293F746869732E62556E646F3A6E756C6C2C732822726573697A6522293F746869';
wwv_flow_imp.g_varchar2_table(542) := '732E656453697A653A6E756C6C2C6E2E6C656E6774683F746869732E6252657365743A6E756C6C5D293B76617220683D66756E6374696F6E28612C642C702C67297B76617220453D662822696E707574222C226D706C75732D65642D72616E6765206D70';
wwv_flow_imp.g_varchar2_table(543) := '6C75732D652D222B612C7B747970653A2272616E6765222C6D696E3A702C6D61783A672C76616C75653A3130302C22617269612D6C6162656C223A647D293B72657475726E20452E6164644576656E744C697374656E65722822696E707574222C66756E';
wwv_flow_imp.g_varchar2_table(544) := '6374696F6E28297B652E65642E61646A5B615D3D2B452E76616C75652C652E65644368616E67656428297D292C7B696E7075743A452C626F783A6628226C6162656C222C226D706C75732D65642D736C69646572222C6E756C6C2C5B6628227370616E22';
wwv_flow_imp.g_varchar2_table(545) := '2C6E756C6C2C7B746578743A647D292C455D297D7D3B746869732E73423D68282262222C6F28224252494748544E45535322292C34302C313630292C746869732E73433D68282263222C6F2822434F4E545241535422292C34302C313630292C74686973';
wwv_flow_imp.g_varchar2_table(546) := '2E73533D68282273222C6F282253415455524154494F4E22292C302C323030292C746869732E656441646A7573743D662822646976222C226D706C75732D65642D61646A757374222C7B68696464656E3A21307D2C5B746869732E73422E626F782C7468';
wwv_flow_imp.g_varchar2_table(547) := '69732E73432E626F782C746869732E73532E626F785D292C746869732E65644D6574613D6628227370616E222C226D706C75732D65642D6D657461222C7B22617269612D6C697665223A22706F6C697465227D292C746869732E70686F746F426F783D66';
wwv_flow_imp.g_varchar2_table(548) := '2822646976222C226D706C75732D6564222C7B68696464656E3A21307D2C5B662822646976222C226D706C75732D65642D7374616765222C6E756C6C2C5B746869732E6564577261705D292C746869732E6564546F6F6C732C746869732E656441646A75';
wwv_flow_imp.g_varchar2_table(549) := '73742C746869732E65644D6574615D292C5328746869732E656443726F702C73282263726F7022297C7C212175292C746869732E62526F744C2E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B652E6564526F';
wwv_flow_imp.g_varchar2_table(550) := '74617465282D3930297D292C746869732E62526F74522E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B652E6564526F74617465283930297D292C746869732E62466C69702E6164644576656E744C69737465';
wwv_flow_imp.g_varchar2_table(551) := '6E65722822636C69636B222C66756E6374696F6E28297B652E6564466C697028297D292C746869732E6241646A7573742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B76617220613D652E656441646A7573';
wwv_flow_imp.g_varchar2_table(552) := '742E68696464656E3B5328652E656441646A7573742C61292C652E6241646A7573742E7365744174747269627574652822617269612D70726573736564222C537472696E67286129297D292C746869732E62477261792E6164644576656E744C69737465';
wwv_flow_imp.g_varchar2_table(553) := '6E65722822636C69636B222C66756E6374696F6E28297B652E65642E677261793D21652E65642E677261792C652E62477261792E7365744174747269627574652822617269612D70726573736564222C537472696E6728652E65642E6772617929292C65';
wwv_flow_imp.g_varchar2_table(554) := '2E65644368616E67656428297D292C746869732E62447261772E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B652E656453657444726177696E672821652E65642E64726177696E67297D292C746869732E62';
wwv_flow_imp.g_varchar2_table(555) := '556E646F2E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B652E65642E7374726F6B65732E706F7028292C652E65644368616E67656428297D292C746869732E6252657365742E6164644576656E744C697374';
wwv_flow_imp.g_varchar2_table(556) := '656E65722822636C69636B222C66756E6374696F6E28297B652E6564526573657428297D292C746869732E6564526174696F2E6164644576656E744C697374656E657228226368616E6765222C66756E6374696F6E28297B652E6564536574526174696F';
wwv_flow_imp.g_varchar2_table(557) := '28652E6564526174696F2E76616C7565297D292C746869732E656453697A652E6164644576656E744C697374656E657228226368616E6765222C66756E6374696F6E28297B652E65642E736964653D2B652E656453697A652E76616C75652C652E656443';
wwv_flow_imp.g_varchar2_table(558) := '68616E676564282130297D292C746869732E656443726F702E6164644576656E744C697374656E65722822706F696E746572646F776E222C66756E6374696F6E2861297B652E6564506F696E74657228612C612E7461726765742E676574417474726962';
wwv_flow_imp.g_varchar2_table(559) := '7574652822646174612D6822297C7C226D6F766522297D292C746869732E656443616E7661732E6164644576656E744C697374656E65722822706F696E746572646F776E222C66756E6374696F6E2861297B652E65642626652E65642E64726177696E67';
wwv_flow_imp.g_varchar2_table(560) := '2626652E65644472617753746172742861297D292C746869732E656443726F702E6164644576656E744C697374656E657228226B6579646F776E222C66756E6374696F6E2861297B76617220643D7B4172726F774C6566743A5B2D312C305D2C4172726F';
wwv_flow_imp.g_varchar2_table(561) := '7752696768743A5B312C305D2C4172726F7755703A5B302C2D315D2C4172726F77446F776E3A5B302C315D7D5B612E6B65795D3B696628212821647C7C21652E656429297B612E70726576656E7444656661756C7428293B76617220703D6E742E657874';
wwv_flow_imp.g_varchar2_table(562) := '656E64287B7D2C652E65642E63726F70293B652E65644472616728612E73686966744B65793F645B305D3F2265223A2273223A226D6F7665222C702C645B305D2A2E30322C645B315D2A2E3032292C652E6564506C61636543726F7028292C652E656443';
wwv_flow_imp.g_varchar2_table(563) := '68616E676564282130297D7D292C77696E646F772E6164644576656E744C697374656E65722822726573697A65222C66756E6374696F6E28297B652E65642626652E73746174653D3D3D22726576696577222626652E656452656E64657228297D297D2C';
wwv_flow_imp.g_varchar2_table(564) := '632E70726F746F747970652E656454573D66756E6374696F6E28297B72657475726E20746869732E65642E726F74253138303F746869732E65642E7372632E6865696768743A746869732E65642E7372632E77696474687D2C632E70726F746F74797065';
wwv_flow_imp.g_varchar2_table(565) := '2E656454483D66756E6374696F6E28297B72657475726E20746869732E65642E726F74253138303F746869732E65642E7372632E77696474683A746869732E65642E7372632E6865696768747D2C632E70726F746F747970652E65644C6F61643D66756E';
wwv_flow_imp.g_varchar2_table(566) := '6374696F6E2874297B76617220653D746869733B72657475726E2068652874292E7468656E2866756E6374696F6E2869297B652E65643D7B7372633A692C726F743A302C666C69703A21312C63726F703A7B783A302C793A302C773A312C683A317D2C72';
wwv_flow_imp.g_varchar2_table(567) := '6174696F3A302C61646A3A7B623A3130302C633A3130302C733A3130307D2C677261793A21312C7374726F6B65733A5B5D2C636F6C6F75723A50745B305D2C64726177696E673A21312C736964653A652E6366672E696D6167654D6178536964657C7C31';
wwv_flow_imp.g_varchar2_table(568) := '3932307D2C652E656456657273696F6E3D302C652E656443616368653D652E6564427573793D6E756C6C2C652E6564457374696D6174653D6E756C6C2C652E6564436F6E74726F6C73526573657428292C53745B652E6366672E63726F70526174696F5D';
wwv_flow_imp.g_varchar2_table(569) := '2626652E6564536574526174696F28652E6366672E63726F70526174696F2C2130297D297D2C632E70726F746F747970652E6564436F6E74726F6C7352657365743D66756E6374696F6E28297B76617220743D746869733B5B746869732E73422C746869';
wwv_flow_imp.g_varchar2_table(570) := '732E73432C746869732E73535D2E666F72456163682866756E6374696F6E2865297B652E696E7075742E76616C75653D3130307D292C746869732E6564526174696F2E76616C75653D2246524545222C746869732E656453697A652E73656C6563746564';
wwv_flow_imp.g_varchar2_table(571) := '496E6465783D302C5328746869732E656441646A7573742C2131292C5B746869732E6241646A7573742C746869732E62477261792C746869732E62447261775D2E666F72456163682866756E6374696F6E2865297B652E73657441747472696275746528';
wwv_flow_imp.g_varchar2_table(572) := '22617269612D70726573736564222C2266616C736522297D292C41727261792E70726F746F747970652E666F72456163682E63616C6C28746869732E6564436F6C6F7572732E6368696C6472656E2C66756E6374696F6E28652C69297B652E7365744174';
wwv_flow_imp.g_varchar2_table(573) := '747269627574652822617269612D70726573736564222C537472696E6728216929297D292C5328746869732E6564436F6C6F7572732C2131292C5328746869732E62556E646F2C2131292C746869732E70686F746F426F782E636C6173734C6973742E72';
wwv_flow_imp.g_varchar2_table(574) := '656D6F7665282269732D64726177696E6722292C742E656443726F70262628742E656443726F702E7374796C652E706F696E7465724576656E74733D2222297D2C632E70726F746F747970652E656452657365743D66756E6374696F6E28297B76617220';
wwv_flow_imp.g_varchar2_table(575) := '743D746869732E65643B742E726F743D302C742E666C69703D21312C742E63726F703D7B783A302C793A302C773A312C683A317D2C742E726174696F3D302C742E61646A3D7B623A3130302C633A3130302C733A3130307D2C742E677261793D21312C74';
wwv_flow_imp.g_varchar2_table(576) := '2E7374726F6B65733D5B5D2C742E64726177696E673D21312C742E736964653D746869732E6366672E696D6167654D6178536964657C7C313932302C746869732E6564436F6E74726F6C73526573657428292C53745B746869732E6366672E63726F7052';
wwv_flow_imp.g_varchar2_table(577) := '6174696F5D2626746869732E6564536574526174696F28746869732E6366672E63726F70526174696F2C2130292C746869732E65644368616E67656428297D2C632E70726F746F747970652E656452656E6465723D66756E6374696F6E28297B69662874';
wwv_flow_imp.g_varchar2_table(578) := '6869732E6564297B76617220743D77696E646F772E646576696365506978656C526174696F7C7C312C653D4D6174682E6D696E28323034382C4D6174682E6D6178283634302C4D6174682E726F756E642828746869732E726F6F742E636C69656E745769';
wwv_flow_imp.g_varchar2_table(579) := '6474687C7C383030292A742929292C693D6A7428746869732E65642C652C2131292C6E3D746869732E656443616E7661733B6E2E77696474683D692E77696474682C6E2E6865696768743D692E6865696768742C6E2E676574436F6E7465787428223264';
wwv_flow_imp.g_varchar2_table(580) := '22292E64726177496D61676528692C302C30292C746869732E6564506C61636543726F7028292C746869732E65644D65746155706461746528297D7D2C632E70726F746F747970652E6564506C61636543726F703D66756E6374696F6E28297B76617220';
wwv_flow_imp.g_varchar2_table(581) := '743D746869732E65642E63726F702C653D746869732E656443726F702E7374796C653B652E6C6566743D742E782A3130302B2225222C652E746F703D742E792A3130302B2225222C652E77696474683D742E772A3130302B2225222C652E686569676874';
wwv_flow_imp.g_varchar2_table(582) := '3D742E682A3130302B2225227D2C632E70726F746F747970652E65644368616E6765643D66756E6374696F6E2874297B76617220653D746869733B746869732E656456657273696F6E2B2B2C746869732E6564457374696D6174653D6E756C6C2C743F74';
wwv_flow_imp.g_varchar2_table(583) := '6869732E65644D65746155706461746528293A746869732E65645261667C7C28746869732E65645261663D72657175657374416E696D6174696F6E4672616D652866756E6374696F6E28297B652E65645261663D6E756C6C2C652E656452656E64657228';
wwv_flow_imp.g_varchar2_table(584) := '297D29292C636C65617254696D656F757428746869732E656454696D6572292C746869732E656454696D65723D73657454696D656F75742866756E6374696F6E28297B76617220693D652E656456657273696F6E3B652E65642626652E65644578706F72';
wwv_flow_imp.g_varchar2_table(585) := '7428292E7468656E2866756E6374696F6E286E297B652E65642626693D3D3D652E656456657273696F6E262628652E6564457374696D6174653D6E2E626C6F622E73697A652C652E65644D6574615570646174652829297D297D2C373030297D2C632E70';
wwv_flow_imp.g_varchar2_table(586) := '726F746F747970652E65644D6574615570646174653D66756E6374696F6E28297B76617220743D746869732E65642C653D742E63726F702C693D652E772A746869732E6564545728292C6E3D652E682A746869732E6564544828292C733D4D6174682E6D';
wwv_flow_imp.g_varchar2_table(587) := '696E28312C742E736964652F4D6174682E6D617828692C6E29293B746869732E65644D6574612E74657874436F6E74656E743D6F282250484F544F5F4D455441222C4D6174682E726F756E6428692A73292C4D6174682E726F756E64286E2A7329292B28';
wwv_flow_imp.g_varchar2_table(588) := '746869732E6564457374696D6174653F22205C78423720222B6F282250484F544F5F53495A45222C4428746869732E6564457374696D61746529293A2222297D2C632E70726F746F747970652E65644578706F72743D66756E6374696F6E28297B766172';
wwv_flow_imp.g_varchar2_table(589) := '20743D746869732C653D746869732E656456657273696F6E2C693D746869732E6366672C6E3D7B504E473A22696D6167652F706E67222C574542503A22696D6167652F77656270227D5B692E696D616765466F726D61745D7C7C22696D6167652F6A7065';
wwv_flow_imp.g_varchar2_table(590) := '67223B696628746869732E656443616368652626746869732E656443616368652E763D3D3D652972657475726E2050726F6D6973652E7265736F6C766528746869732E656443616368652E72293B696628746869732E6564427573792626746869732E65';
wwv_flow_imp.g_varchar2_table(591) := '64427573792E763D3D3D652972657475726E20746869732E6564427573792E703B76617220733D706528746869732E65642C746869732E65642E736964652C6E2C4D6174682E6D696E28312C4D6174682E6D6178282E332C28692E696D6167655175616C';
wwv_flow_imp.g_varchar2_table(592) := '6974797C7C3835292F31303029292C692E6D61784279746573292E7468656E2866756E6374696F6E2872297B72657475726E20742E656443616368653D7B763A652C727D2C727D293B72657475726E20746869732E6564427573793D7B763A652C703A73';
wwv_flow_imp.g_varchar2_table(593) := '7D2C737D2C632E70726F746F747970652E6564526F746174653D66756E6374696F6E2874297B76617220653D746869732E65642C693D652E63726F703B652E726F743D28652E726F742B742B33363029253336302C652E63726F703D743E303F7B783A31';
wwv_flow_imp.g_varchar2_table(594) := '2D28692E792B692E68292C793A692E782C773A692E682C683A692E777D3A7B783A692E792C793A312D28692E782B692E77292C773A692E682C683A692E777D2C652E726174696F2626746869732E656446697428652E726174696F292C746869732E6564';
wwv_flow_imp.g_varchar2_table(595) := '4368616E67656428297D2C632E70726F746F747970652E6564466C69703D66756E6374696F6E28297B76617220743D746869732E65643B742E666C69703D21742E666C69702C742E726F743D283336302D742E726F7429253336302C742E63726F703D7B';
wwv_flow_imp.g_varchar2_table(596) := '783A312D742E63726F702E782D742E63726F702E772C793A742E63726F702E792C773A742E63726F702E772C683A742E63726F702E687D2C746869732E65644368616E67656428297D2C632E70726F746F747970652E65644669743D66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(597) := '2874297B76617220653D742A746869732E6564544828292F746869732E6564545728292C693D653E3D313F313A652C6E3D653E3D313F312F653A313B746869732E65642E63726F703D7B783A28312D69292F322C793A28312D6E292F322C773A692C683A';
wwv_flow_imp.g_varchar2_table(598) := '6E7D7D2C632E70726F746F747970652E6564536574526174696F3D66756E6374696F6E28742C65297B76617220693D746869732E65643B743D3D3D22414C4C223F28692E726174696F3D302C692E63726F703D7B783A302C793A302C773A312C683A317D';
wwv_flow_imp.g_varchar2_table(599) := '2C746869732E6564526174696F2E76616C75653D224652454522293A28692E726174696F3D53745B745D7C7C302C692E726174696F2626746869732E656446697428692E726174696F29292C657C7C28746869732E6564506C61636543726F7028292C74';
wwv_flow_imp.g_varchar2_table(600) := '6869732E65644368616E67656428213029297D2C632E70726F746F747970652E656453657444726177696E673D66756E6374696F6E2874297B746869732E65642E64726177696E673D742C746869732E62447261772E7365744174747269627574652822';
wwv_flow_imp.g_varchar2_table(601) := '617269612D70726573736564222C537472696E67287429292C746869732E70686F746F426F782E636C6173734C6973742E746F67676C65282269732D64726177696E67222C74292C746869732E656443726F702E7374796C652E706F696E746572457665';
wwv_flow_imp.g_varchar2_table(602) := '6E74733D743F226E6F6E65223A22222C5328746869732E6564436F6C6F7572732C74292C5328746869732E62556E646F2C74297D2C632E70726F746F747970652E6564447261673D66756E6374696F6E28742C652C692C6E297B76617220733D74686973';
wwv_flow_imp.g_varchar2_table(603) := '2E65642C723D2E30352C753D732E726174696F3F732E726174696F2A746869732E6564544828292F746869732E6564545728293A302C6C3D652E782C683D652E792C613D652E782B652E772C643D652E792B652E683B696628743D3D3D226D6F76652229';
wwv_flow_imp.g_varchar2_table(604) := '7B732E63726F703D7B783A4D6174682E6D696E28312D652E772C4D6174682E6D617828302C6C2B6929292C793A4D6174682E6D696E28312D652E682C4D6174682E6D617828302C682B6E29292C773A652E772C683A652E687D3B72657475726E7D742E69';
wwv_flow_imp.g_varchar2_table(605) := '6E6465784F6628227722293E3D302626286C3D4D6174682E6D696E28612D722C4D6174682E6D617828302C6C2B692929292C742E696E6465784F6628226522293E3D30262628613D4D6174682E6D6178286C2B722C4D6174682E6D696E28312C612B6929';
wwv_flow_imp.g_varchar2_table(606) := '29292C742E696E6465784F6628226E22293E3D30262628683D4D6174682E6D696E28642D722C4D6174682E6D617828302C682B6E2929292C742E696E6465784F6628227322293E3D30262628643D4D6174682E6D617828682B722C4D6174682E6D696E28';
wwv_flow_imp.g_varchar2_table(607) := '312C642B6E2929293B76617220703D612D6C2C673D642D683B75262628743D3D3D226E227C7C743D3D3D2273223F703D672A753A673D702F752C703E31262628703D312C673D702F75292C673E31262628673D312C703D672A75292C6C3D742E696E6465';
wwv_flow_imp.g_varchar2_table(608) := '784F6628227722293E3D303F612D703A742E696E6465784F6628226522293E3D303F6C3A652E782B652E772F322D702F322C683D742E696E6465784F6628226E22293E3D303F642D673A742E696E6465784F6628227322293E3D303F683A652E792B652E';
wwv_flow_imp.g_varchar2_table(609) := '682F322D672F322C6C3D4D6174682E6D696E284D6174682E6D617828302C6C292C312D70292C683D4D6174682E6D696E284D6174682E6D617828302C68292C312D6729292C732E63726F703D7B783A6C2C793A682C773A702C683A677D7D2C632E70726F';
wwv_flow_imp.g_varchar2_table(610) := '746F747970652E6564506F696E7465723D66756E6374696F6E28742C65297B696628212821746869732E65647C7C742E627574746F6E3E3029297B76617220693D746869732C6E3D746869732E6564577261702E676574426F756E64696E67436C69656E';
wwv_flow_imp.g_varchar2_table(611) := '745265637428292C733D6E742E657874656E64287B7D2C746869732E65642E63726F70292C723D742E636C69656E74582C753D742E636C69656E74592C6C3D742E7461726765743B742E70726576656E7444656661756C7428293B7472797B6C2E736574';
wwv_flow_imp.g_varchar2_table(612) := '506F696E7465724361707475726528742E706F696E7465724964297D63617463687B7D76617220683D66756E6374696F6E2864297B692E65644472616728652C732C28642E636C69656E74582D72292F6E2E77696474682C28642E636C69656E74592D75';
wwv_flow_imp.g_varchar2_table(613) := '292F6E2E686569676874292C692E6564506C61636543726F7028297D2C613D66756E6374696F6E28297B6C2E72656D6F76654576656E744C697374656E65722822706F696E7465726D6F7665222C68292C6C2E72656D6F76654576656E744C697374656E';
wwv_flow_imp.g_varchar2_table(614) := '65722822706F696E7465727570222C61292C6C2E72656D6F76654576656E744C697374656E65722822706F696E74657263616E63656C222C61292C692E65644368616E676564282130297D3B6C2E6164644576656E744C697374656E65722822706F696E';
wwv_flow_imp.g_varchar2_table(615) := '7465726D6F7665222C68292C6C2E6164644576656E744C697374656E65722822706F696E7465727570222C61292C6C2E6164644576656E744C697374656E65722822706F696E74657263616E63656C222C61297D7D2C632E70726F746F747970652E6564';
wwv_flow_imp.g_varchar2_table(616) := '546F536F757263653D66756E6374696F6E28742C65297B76617220693D746869732E65642C6E3D692E7372632E77696474682C733D692E7372632E6865696768742C723D28742D2E35292A746869732E6564545728292C753D28652D2E35292A74686973';
wwv_flow_imp.g_varchar2_table(617) := '2E6564544828292C6C3D692E726F742A4D6174682E50492F3138302C683D4D6174682E726F756E64284D6174682E636F73286C29292C613D4D6174682E726F756E64284D6174682E73696E286C29292C643D722A682B752A612C703D2D722A612B752A68';
wwv_flow_imp.g_varchar2_table(618) := '3B72657475726E20692E666C6970262628643D2D64292C5B28642B6E2F32292F6E2C28702B732F32292F735D7D2C632E70726F746F747970652E65644472617753746172743D66756E6374696F6E2874297B76617220653D746869732C693D746869732E';
wwv_flow_imp.g_varchar2_table(619) := '65642C6E3D746869732E656443616E7661732C733D6E2E676574426F756E64696E67436C69656E745265637428292C723D6E2E676574436F6E746578742822326422292C753D7B636F6C6F75723A692E636F6C6F75722C773A2E3030362C7074733A5B5D';
wwv_flow_imp.g_varchar2_table(620) := '7D2C6C3D6E756C6C3B742E70726576656E7444656661756C7428293B7472797B6E2E736574506F696E7465724361707475726528742E706F696E7465724964297D63617463687B7D76617220683D66756E6374696F6E2864297B76617220703D4D617468';
wwv_flow_imp.g_varchar2_table(621) := '2E6D696E28312C4D6174682E6D617828302C28642E636C69656E74582D732E6C656674292F732E776964746829292C673D4D6174682E6D696E28312C4D6174682E6D617828302C28642E636C69656E74592D732E746F70292F732E68656967687429292C';
wwv_flow_imp.g_varchar2_table(622) := '453D702A6E2E77696474682C523D672A6E2E6865696768743B752E7074732E7075736828652E6564546F536F7572636528702C6729292C722E7374726F6B655374796C653D752E636F6C6F75722C722E6C696E6557696474683D4D6174682E6D61782831';
wwv_flow_imp.g_varchar2_table(623) := '2C752E772A4D6174682E6D6178286E2E77696474682C6E2E68656967687429292C722E6C696E654361703D722E6C696E654A6F696E3D22726F756E64222C722E626567696E5061746828292C722E6D6F7665546F286C3F6C5B305D3A452C6C3F6C5B315D';
wwv_flow_imp.g_varchar2_table(624) := '3A52292C722E6C696E65546F28452B286C3F303A2E31292C52292C722E7374726F6B6528292C6C3D5B452C525D7D2C613D66756E6374696F6E28297B6E2E72656D6F76654576656E744C697374656E65722822706F696E7465726D6F7665222C68292C6E';
wwv_flow_imp.g_varchar2_table(625) := '2E72656D6F76654576656E744C697374656E65722822706F696E7465727570222C61292C6E2E72656D6F76654576656E744C697374656E65722822706F696E74657263616E63656C222C61292C752E7074732E6C656E6774682626692E7374726F6B6573';
wwv_flow_imp.g_varchar2_table(626) := '2E707573682875292C652E65644368616E67656428297D3B682874292C6E2E6164644576656E744C697374656E65722822706F696E7465726D6F7665222C68292C6E2E6164644576656E744C697374656E65722822706F696E7465727570222C61292C6E';
wwv_flow_imp.g_varchar2_table(627) := '2E6164644576656E744C697374656E65722822706F696E74657263616E63656C222C61297D2C632E70726F746F747970652E6A6F696E65643D66756E6374696F6E28297B72657475726E20746869732E6974656D732E66696C7465722866756E6374696F';
wwv_flow_imp.g_varchar2_table(628) := '6E2874297B72657475726E20742E7365717D292E6D61702866756E6374696F6E2874297B72657475726E20742E7472616E7363726970747D292E66696C74657228426F6F6C65616E292E6A6F696E28600A0A60297D2C632E70726F746F747970652E6163';
wwv_flow_imp.g_varchar2_table(629) := '636570743D66756E6374696F6E28297B76617220743D746869732C653D746869732E70656E64696E67426C6F623B696628212821657C7C746869732E746F6F4269677C7C746869732E6564576F726B696E6729297B69662821746869732E6564297B7468';
wwv_flow_imp.g_varchar2_table(630) := '69732E73656E6428652C6E756C6C293B72657475726E7D746869732E6564576F726B696E673D21302C746869732E73796E6328292C746869732E736179286F2822505245504152494E4722292C22696E666F22292C746869732E65644578706F72742829';
wwv_flow_imp.g_varchar2_table(631) := '2E7468656E2866756E6374696F6E2869297B696628742E6564576F726B696E673D21312C21692E66697473297B742E736179286F282250484F544F5F544F4F5F4C41524745222C4428742E6366672E6D6178427974657329292C226572726F7222292C74';
wwv_flow_imp.g_varchar2_table(632) := '2E73746174653D3D3D22726576696577223F742E73796E6328293A742E73686F7752657669657728293B72657475726E7D742E73656E6428692E626C6F622C7B6E616D653A742E70686F746F4E616D6528692E626C6F622E74797065292C77696474683A';
wwv_flow_imp.g_varchar2_table(633) := '692E77696474682C6865696768743A692E6865696768747D297D292E63617463682866756E6374696F6E2869297B742E6564576F726B696E673D21312C742E73796E6328292C742E736179286F282250484F544F5F4641494C4544222C692626692E6D65';
wwv_flow_imp.g_varchar2_table(634) := '73736167657C7C2222292C226572726F7222297D297D7D2C632E70726F746F747970652E73656E643D66756E6374696F6E28742C65297B76617220693D746869732C6E3D742E747970652E73706C697428222F22295B305D3D3D3D22766964656F223F22';
wwv_flow_imp.g_varchar2_table(635) := '766964656F223A742E747970652E73706C697428222F22295B305D3D3D3D22696D616765223F22696D616765223A22617564696F222C733D28742E747970657C7C6E2B222F7765626D22292E73706C697428223B22295B305D2C723D653F652E6E616D65';
wwv_flow_imp.g_varchar2_table(636) := '3A746869732E70656E64696E674E616D657C7C28746869732E75706C6F61644E616D653F746869732E75706C6F61644E616D652E7265706C616365282F5C2E5B5E2E5D2A242F2C2222292E7265706C616365282F5B5E5C772E5C2D205D2B2F672C225F22';
wwv_flow_imp.g_varchar2_table(637) := '292B222E222B67742873293A746869732E66696C654E616D6528732C6E29292C753D653F22223A746869732E726576696577546578742E76616C75652E7472696D28292E736C69636528302C5474292C6C3D653F6E756C6C3A746869732E70656E64696E';
wwv_flow_imp.g_varchar2_table(638) := '675365632C683D7B6E616D653A722C6D696D653A732C6B696E643A6E2E746F55707065724361736528292C73697A653A742E73697A652C6475726174696F6E3A6C2C626C6F623A742C75706C6F6164696E673A302C7472616E7363726970743A752C7769';
wwv_flow_imp.g_varchar2_table(639) := '6474683A653F652E77696474683A6E756C6C2C6865696768743A653F652E6865696768743A6E756C6C7D3B746869732E70656E64696E674E616D653D722C746869732E73617665447261667428292C746869732E636C65617252657669657728292C7468';
wwv_flow_imp.g_varchar2_table(640) := '69732E70656E64696E67426C6F623D6E756C6C2C746869732E736179282222292C746869732E6974656D732E707573682868292C746869732E75706C6F6164696E67417564696F3D6E3D3D3D22617564696F222C746869732E7365745374617465282275';
wwv_flow_imp.g_varchar2_table(641) := '706C6F6164696E6722292C746869732E72656E6465724C69737428292C746869732E75706C6F616428742C68292E7468656E2866756E6374696F6E2861297B76617220643D692E6A6F696E656428293B682E7365713D612E7365712C682E6E616D653D61';
wwv_flow_imp.g_varchar2_table(642) := '2E6E616D652C682E75706C6F6164696E673D6E756C6C2C682E70656E64696E673D21302C612E7472616E736372697074262628682E7472616E7363726970743D612E7472616E736372697074292C692E70656E64696E674E616D653D6E756C6C2C692E75';
wwv_flow_imp.g_varchar2_table(643) := '706C6F61644E616D653D6E756C6C2C692E726177426C6F623D6E756C6C2C692E6661696C65643D21312C692E726576696577546578742E76616C75653D22222C692E64726F70447261667428292C692E7365745374617465282269646C6522292C692E72';
wwv_flow_imp.g_varchar2_table(644) := '656E6465724C69737428292C692E777269746556616C756528642C68292C692E666F6375734E65787428292C692E6669726528227361766564222C7B7365713A612E7365712C6E616D653A612E6E616D652C6D696D65547970653A612E6D696D652C6B69';
wwv_flow_imp.g_varchar2_table(645) := '6E643A612E6B696E642C62797465733A612E73697A652C7365636F6E64733A612E6475726174696F6E2C77696474683A682E77696474682C6865696768743A682E6865696768742C7472616E7363726970743A682E7472616E7363726970747D297D292E';
wwv_flow_imp.g_varchar2_table(646) := '63617463682866756E6374696F6E2861297B76617220643D612626612E73657373696F6E3F6F282253455353494F4E5F454E44454422293A6F282255504C4F41445F4641494C4544222C612626612E6D6573736167657C7C2222293B692E6974656D732E';
wwv_flow_imp.g_varchar2_table(647) := '73706C69636528692E6974656D732E696E6465784F662868292C31292C692E72656E6465724C69737428292C692E70656E64696E67426C6F623D742C692E70656E64696E675365633D6C2C692E726576696577546578742E76616C75653D752C692E6661';
wwv_flow_imp.g_varchar2_table(648) := '696C65643D21302C653F28692E70656E64696E674E616D653D722C692E65644C6F61642874292E7468656E2866756E6374696F6E28297B692E6661696C65643D21302C692E73686F7752657669657728292C692E73617928642C226572726F7222297D29';
wwv_flow_imp.g_varchar2_table(649) := '293A28692E73686F7752657669657728292C692E73617928642C226572726F722229292C692E6669726528226572726F72222C7B726561736F6E3A612626612E73657373696F6E3F2273657373696F6E223A2275706C6F6164222C6D6573736167653A61';
wwv_flow_imp.g_varchar2_table(650) := '2626612E6D6573736167657D297D297D2C632E70726F746F747970652E63616C6C3D66756E6374696F6E2874297B76617220653D746869732E6366672E616A61783B72657475726E206E65772050726F6D6973652866756E6374696F6E28692C6E297B61';
wwv_flow_imp.g_varchar2_table(651) := '7065782E7365727665722E706C7567696E28652C742C7B64617461547970653A226A736F6E227D292E7468656E2866756E6374696F6E2873297B696628732626732E6572726F72297B76617220723D6E6577204572726F7228732E6572726F72293B722E';
wwv_flow_imp.g_varchar2_table(652) := '73657373696F6E3D2F73657373696F6E2F692E7465737428732E6572726F722926262F28657870697265647C656E6465647C696E76616C69647C74696D65643F203F6F7574292F692E7465737428732E6572726F72292C6E2872297D656C736520692873';
wwv_flow_imp.g_varchar2_table(653) := '7C7C7B7D297D2C66756E6374696F6E28732C722C75297B766172206C3D732626732E726573706F6E73654A534F4E2626732E726573706F6E73654A534F4E2E6572726F727C7C28732626732E7374617475733D3D3D303F6F28224E4554574F524B22293A';
wwv_flow_imp.g_varchar2_table(654) := '757C7C727C7C6F28224E4554574F524B2229292C683D6E6577204572726F72286C293B682E73657373696F6E3D212173262628732E7374617475733D3D3D3430317C7C732E7374617475733D3D3D3430337C7C723D3D3D227061727365726572726F7222';
wwv_flow_imp.g_varchar2_table(655) := '26262F3C68746D6C7C6C6F67696E7C7369676E2E3F696E2F692E7465737428732E726573706F6E7365546578747C7C2222297C7C2F73657373696F6E2F692E74657374286C29292C6E2868297D297D297D2C632E70726F746F747970652E75706C6F6164';
wwv_flow_imp.g_varchar2_table(656) := '3D66756E6374696F6E28742C65297B666F722876617220693D746869732C6E3D736528292C733D4D6174682E6D617828312C4D6174682E6365696C28742E73697A652F787429292C723D302C753D302C6C3D66756E6374696F6E28297B696628723E3D73';
wwv_flow_imp.g_varchar2_table(657) := '2972657475726E2050726F6D6973652E7265736F6C766528293B76617220643D722B2B3B72657475726E20726528742E736C69636528642A78742C4D6174682E6D696E28742E73697A652C28642B31292A78742929292E7468656E2866756E6374696F6E';
wwv_flow_imp.g_varchar2_table(658) := '2870297B666F722876617220673D5B5D2C453D303B453C702E6C656E6774683B452B3D4E7429672E7075736828702E73756273747228452C4E7429293B72657475726E20692E63616C6C287B7830313A2250415254222C7830323A6E2C7830333A642C66';
wwv_flow_imp.g_varchar2_table(659) := '30313A677D297D292E7468656E2866756E6374696F6E28297B72657475726E20752B2B2C652E75706C6F6164696E673D4D6174682E726F756E6428752F732A313030292C692E72656E64657250726F67726573732865292C6C28297D297D2C683D5B5D2C';
wwv_flow_imp.g_varchar2_table(660) := '613D303B613C4D6174682E6D696E2851742C73293B612B2B29682E70757368286C2829293B72657475726E2050726F6D6973652E616C6C2868292E7468656E2866756E6374696F6E28297B72657475726E20692E63616C6C287B7830313A2246494E4953';
wwv_flow_imp.g_varchar2_table(661) := '48222C7830323A6E2C7830343A732C7830353A692E6974656D732E66696C7465722866756E6374696F6E2864297B72657475726E20642E7365717D292E6D61702866756E6374696F6E2864297B72657475726E20642E7365717D292E6A6F696E28223A22';
wwv_flow_imp.g_varchar2_table(662) := '292C7830363A692E6C616E672C7830333A4A534F4E2E737472696E67696679287B6E616D653A652E6E616D652C6D696D653A652E6D696D652C6475726174696F6E3A652E6475726174696F6E3F4D6174682E726F756E6428652E6475726174696F6E2A31';
wwv_flow_imp.g_varchar2_table(663) := '30292F31303A6E756C6C2C77696474683A652E77696474687C7C6E756C6C2C6865696768743A652E6865696768747C7C6E756C6C2C7472616E7363726970743A652E7472616E7363726970747C7C6E756C6C7D297D297D297D2C632E70726F746F747970';
wwv_flow_imp.g_varchar2_table(664) := '652E777269746556616C75653D66756E6374696F6E28742C65297B76617220693D746869732E6974656D732E66696C7465722866756E6374696F6E2875297B72657475726E20752E7365717D292E6D61702866756E6374696F6E2875297B72657475726E';
wwv_flow_imp.g_varchar2_table(665) := '20752E7365717D292E6A6F696E28223A22293B746869732E696E7075742E76616C7565213D3D69262628746869732E696E7075742E76616C75653D692C6E7428746869732E696E707574292E7472696767657228226368616E67652229293B766172206E';
wwv_flow_imp.g_varchar2_table(666) := '3D746869732E6366672E7472616E7363726970744974656D2626617065782E6974656D28746869732E6366672E7472616E7363726970744974656D293B6966286E26266E2E6E6F6465297B76617220733D537472696E67286E2E67657456616C75652829';
wwv_flow_imp.g_varchar2_table(667) := '7C7C2222292C723D746869732E6A6F696E656428293B732E7472696D28293D3D3D537472696E6728747C7C2222292E7472696D28293F6E2E73657456616C75652872293A652626652E7472616E73637269707426266E2E73657456616C756528732E7265';
wwv_flow_imp.g_varchar2_table(668) := '706C616365282F5C732B242F2C2222292B28732E7472696D28293F600A0A603A2222292B652E7472616E736372697074297D7D2C632E70726F746F747970652E6D6564696155726C3D66756E6374696F6E2874297B696628742E626C6F62297265747572';
wwv_flow_imp.g_varchar2_table(669) := '6E20742E75726C7C7C28742E75726C3D55524C2E6372656174654F626A65637455524C28742E626C6F6229292C50726F6D6973652E7265736F6C766528742E75726C293B696628742E75726C2972657475726E2050726F6D6973652E7265736F6C766528';
wwv_flow_imp.g_varchar2_table(670) := '742E75726C293B76617220653D617065782E7365727665722E706C7567696E55726C28746869732E6366672E616A61782C742E726F773F7B7830313A225341564544222C7830323A742E726F777D3A7B7830313A22474554222C7830323A742E7365717D';
wwv_flow_imp.g_varchar2_table(671) := '293B72657475726E20666574636828652C7B63726564656E7469616C733A2273616D652D6F726967696E227D292E7468656E2866756E6374696F6E2869297B69662821692E6F6B297468726F77206E6577204572726F7228692E7374617475732B222022';
wwv_flow_imp.g_varchar2_table(672) := '2B692E73746174757354657874293B72657475726E20692E626C6F6228297D292E7468656E2866756E6374696F6E2869297B72657475726E20742E75726C3D55524C2E6372656174654F626A65637455524C28692E747970653F693A6E657720426C6F62';
wwv_flow_imp.g_varchar2_table(673) := '285B695D2C7B747970653A742E6D696D657C7C22227D29292C742E75726C7D297D2C632E70726F746F747970652E72656E64657250726F67726573733D66756E6374696F6E2874297B696628742E6C69297B76617220653D742E6C692E71756572795365';
wwv_flow_imp.g_varchar2_table(674) := '6C6563746F7228222E6D706C75732D726F772D70726F6772657373207370616E22292C693D742E6C692E717565727953656C6563746F7228222E6D706C75732D726F772D6D65746122293B65262628652E7374796C652E77696474683D28742E75706C6F';
wwv_flow_imp.g_varchar2_table(675) := '6164696E677C7C30292B222522292C69262628692E74657874436F6E74656E743D742E75706C6F6164696E673E3D3130302626746869732E6366672E7472616E736372697074696F6E3D3D3D22534552564552222626742E6B696E643D3D3D2241554449';
wwv_flow_imp.g_varchar2_table(676) := '4F223F6F28225452414E5343524942494E475F53455256455222292B222E2E2E223A6F282255504C4F41445F50524F4752455353222C742E75706C6F6164696E677C7C3029297D7D2C632E70726F746F747970652E72656E6465724C6973743D66756E63';
wwv_flow_imp.g_varchar2_table(677) := '74696F6E28297B76617220743D746869732C653D746869732E6366672E726561644F6E6C797C7C746869732E64697361626C65642C693D746869732E73617665642E6D61702866756E6374696F6E286E297B72657475726E206E2E697353617665643D21';
wwv_flow_imp.g_varchar2_table(678) := '302C6E2E6B696E643D6E2E6B696E647C7C6C65286E2E6D696D65292C6E7D292E636F6E63617428746869732E6974656D73293B746869732E6C6973742E696E6E657248544D4C3D22222C692E666F72456163682866756E6374696F6E286E2C73297B7661';
wwv_flow_imp.g_varchar2_table(679) := '7220723D6E2E6B696E643D3D3D22564944454F222C753D6E2E6B696E643D3D3D22494D414745222C6C3D6E2E6E616D657C7C6F286E2E6B696E647C7C22415544494F22292B2220222B28732B31292C683D5B6E2E6475726174696F6E3F58286E2E647572';
wwv_flow_imp.g_varchar2_table(680) := '6174696F6E293A6E756C6C2C6E2E776964746826266E2E6865696768743F6F282250484F544F5F4D455441222C6E2E77696474682C6E2E686569676874293A6E756C6C2C6E2E73697A653F44286E2E73697A65293A6E756C6C5D2E66696C74657228426F';
wwv_flow_imp.g_varchar2_table(681) := '6F6C65616E292E6A6F696E2822205C7842372022292C613D6E2E75706C6F6164696E67213D3D766F6964203026266E2E75706C6F6164696E67213D3D6E756C6C2C643D6628227370616E222C226D706C75732D726F772D69636F222C7B22617269612D68';
wwv_flow_imp.g_varchar2_table(682) := '696464656E223A2274727565227D2C5B6628227370616E222C22666120222B28753F2266612D63616D657261223A723F2266612D766964656F2D63616D657261223A2266612D6D6963726F70686F6E652229295D292C703D753F447428226D706C75732D';
wwv_flow_imp.g_varchar2_table(683) := '722D706C6179222C2266612D657965222C6F2822564945572229293A447428226D706C75732D722D706C6179222C2266612D706C6179222C6F2822504C41592229292C673D447428226D706C75732D722D64656C222C2266612D74726173682D6F222C6F';
wwv_flow_imp.g_varchar2_table(684) := '282244454C4554452229292C453D66282261222C22742D427574746F6E20742D427574746F6E2D2D736D616C6C20742D427574746F6E2D2D6E6F554920742D427574746F6E2D2D6E6F4C6162656C20742D427574746F6E2D2D69636F6E206D706C75732D';
wwv_flow_imp.g_varchar2_table(685) := '722D646F776E222C7B687265663A2223222C7469746C653A6F2822444F574E4C4F414422292C22617269612D6C6162656C223A6F2822444F574E4C4F414422292C646F776E6C6F61643A6C7D2C5B4374282266612D646F776E6C6F616422295D292C523D';
wwv_flow_imp.g_varchar2_table(686) := '662822646976222C226D706C75732D726F772D706C61796572222C7B68696464656E3A21307D292C6B3D6628226C69222C226D706C75732D726F77222B28613F222069732D75706C6F6164696E67223A2222292B28753F22206D706C75732D726F772D2D';
wwv_flow_imp.g_varchar2_table(687) := '696D616765223A2222292C6E756C6C2C5B642C662822646976222C226D706C75732D726F772D6D61696E222C6E756C6C2C5B6628227370616E222C226D706C75732D726F772D6E616D65222C7B746578743A6C2C7469746C653A6C7D292C662822737061';
wwv_flow_imp.g_varchar2_table(688) := '6E222C226D706C75732D726F772D6D657461222C7B746578743A687D292C6E2E697353617665643F6628227370616E222C226D706C75732D746167206D706C75732D7461672D2D7361766564222C7B746578743A6F2822534156454422297D293A6E2E73';
wwv_flow_imp.g_varchar2_table(689) := '6571262621653F6628227370616E222C226D706C75732D746167222C7B746578743A6F282250454E44494E4722297D293A6E756C6C2C613F6628227370616E222C226D706C75732D726F772D70726F6772657373222C6E756C6C2C5B6628227370616E22';
wwv_flow_imp.g_varchar2_table(690) := '295D293A6E756C6C5D292C6628227370616E222C226D706C75732D726F772D62746E73222C6E756C6C2C5B6E2E7365717C7C6E2E726F773F703A6E756C6C2C286E2E7365717C7C6E2E726F77292626742E6861732822646F776E6C6F616422293F453A6E';
wwv_flow_imp.g_varchar2_table(691) := '756C6C2C6E2E7365712626216E2E69735361766564262621653F673A6E756C6C5D292C6E2E7472616E7363726970743F662822646976222C226D706C75732D726F772D74657874222C7B746578743A6E2E7472616E7363726970742C7469746C653A6E2E';
wwv_flow_imp.g_varchar2_table(692) := '7472616E7363726970747D293A6E756C6C2C525D293B6E2E6C693D6B2C752626286E2E626C6F627C7C6E2E75726C292626742E6D6564696155726C286E292E7468656E2866756E6374696F6E2848297B642E696E6E657248544D4C3D22222C642E617070';
wwv_flow_imp.g_varchar2_table(693) := '656E644368696C6428662822696D67222C226D706C75732D726F772D7468756D62222C7B7372633A482C616C743A22227D29297D292C702E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E746F67676C65';
wwv_flow_imp.g_varchar2_table(694) := '506C6179286E2C702C52297D292C452E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2848297B452E67657441747472696275746528226872656622293D3D3D222322262628482E70726576656E7444656661756C74';
wwv_flow_imp.g_varchar2_table(695) := '28292C742E6D6564696155726C286E292E7468656E2866756E6374696F6E284F297B452E687265663D4F2C452E636C69636B28297D29297D292C672E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E28297B742E7265';
wwv_flow_imp.g_varchar2_table(696) := '6D6F7665286E297D292C742E6C6973742E617070656E644368696C64286B292C612626742E72656E64657250726F6772657373286E297D292C5328746869732E6C6973742C692E6C656E6774683E30297D2C632E70726F746F747970652E746F67676C65';
wwv_flow_imp.g_varchar2_table(697) := '506C61793D66756E6374696F6E28742C652C69297B766172206E3D746869732C733D742E6B696E643D3D3D22494D414745222C723D66756E6374696F6E286C2C68297B652E717565727953656C6563746F7228222E742D49636F6E22292E636C6173734E';
wwv_flow_imp.g_varchar2_table(698) := '616D653D22742D49636F6E20666120222B6C2C652E7469746C653D682C652E7365744174747269627574652822617269612D6C6162656C222C68297D3B69662821692E68696464656E297B76617220753D692E717565727953656C6563746F7228226175';
wwv_flow_imp.g_varchar2_table(699) := '64696F2C766964656F22293B752626752E706175736528292C692E68696464656E3D21302C692E696E6E657248544D4C3D22222C7228733F2266612D657965223A2266612D706C6179222C6F28733F2256494557223A22504C41592229293B7265747572';
wwv_flow_imp.g_varchar2_table(700) := '6E7D652E64697361626C65643D21302C746869732E6D6564696155726C2874292E7468656E2866756E6374696F6E286C297B76617220683D742E6B696E643D3D3D22564944454F222C613B696628692E696E6E657248544D4C3D22222C73297B613D6628';
wwv_flow_imp.g_varchar2_table(701) := '22696D67222C226D706C75732D70686F746F222C7B7372633A6C2C616C743A742E6E616D657C7C22227D292C692E617070656E644368696C642861293B76617220643D742E6C692626742E6C692E717565727953656C6563746F7228222E6D706C75732D';
wwv_flow_imp.g_varchar2_table(702) := '726F772D69636F22293B64262621642E717565727953656C6563746F722822696D672229262628642E696E6E657248544D4C3D22222C642E617070656E644368696C6428662822696D67222C226D706C75732D726F772D7468756D62222C7B7372633A6C';
wwv_flow_imp.g_varchar2_table(703) := '2C616C743A22227D2929297D656C736520613D6628683F22766964656F223A22617564696F222C226D706C75732D6D65646961222C7B636F6E74726F6C733A21302C706C617973696E6C696E653A683F21303A6E756C6C2C7072656C6F61643A226D6574';
wwv_flow_imp.g_varchar2_table(704) := '6164617461227D292C612E6164644576656E744C697374656E65722822706C6179222C66756E6374696F6E28297B66742822706C61796261636B22297D292C6B742861292C612E7372633D6C2C692E617070656E644368696C642861292C612E706C6179';
wwv_flow_imp.g_varchar2_table(705) := '28292E63617463682866756E6374696F6E28297B7D293B692E68696464656E3D21312C72282266612D63686576726F6E2D7570222C6F28733F2248494445223A22484944455F504C415945522229297D292E63617463682866756E6374696F6E286C297B';
wwv_flow_imp.g_varchar2_table(706) := '6E2E736179286F2822504C41595F4641494C4544222C6C2E6D657373616765292C226572726F7222297D292E66696E616C6C792866756E6374696F6E28297B652E64697361626C65643D21317D297D2C632E70726F746F747970652E72656D6F76653D66';
wwv_flow_imp.g_varchar2_table(707) := '756E6374696F6E2874297B76617220653D746869732C693D66756E6374696F6E28297B652E63616C6C287B7830313A2244454C455445222C7830323A742E7365717D292E7468656E2866756E6374696F6E28297B766172206E3D652E6A6F696E65642829';
wwv_flow_imp.g_varchar2_table(708) := '3B742E75726C262655524C2E7265766F6B654F626A65637455524C28742E75726C292C652E6974656D732E73706C69636528652E6974656D732E696E6465784F662874292C31292C652E72656E6465724C69737428292C652E777269746556616C756528';
wwv_flow_imp.g_varchar2_table(709) := '6E2C6E756C6C292C652E73796E6328292C652E666F6375734E65787428292C652E66697265282264656C657465222C7B7365713A742E7365712C6E616D653A742E6E616D657D297D292E63617463682866756E6374696F6E286E297B652E736179286E2E';
wwv_flow_imp.g_varchar2_table(710) := '73657373696F6E3F6F282253455353494F4E5F454E44454422293A6E2E6D6573736167652C226572726F7222297D297D3B746869732E6861732822636F6E6669726D44656C65746522293F617065782E6D6573736167652E636F6E6669726D286F282243';
wwv_flow_imp.g_varchar2_table(711) := '4F4E4649524D5F44454C45544522292C66756E6374696F6E286E297B6E26266928297D293A6928297D2C632E70726F746F747970652E73657456616C75653D66756E6374696F6E2874297B76617220653D537472696E6728747C7C2222292E73706C6974';
wwv_flow_imp.g_varchar2_table(712) := '28223A22293B746869732E6974656D733D746869732E6974656D732E66696C7465722866756E6374696F6E2869297B72657475726E20692E7365712626652E696E6465784F6628537472696E6728692E73657129293E3D307D292C746869732E696E7075';
wwv_flow_imp.g_varchar2_table(713) := '742E76616C75653D746869732E6974656D732E6D61702866756E6374696F6E2869297B72657475726E20692E7365717D292E6A6F696E28223A22292C746869732E72656E6465724C69737428292C746869732E73796E6328297D2C632E70726F746F7479';
wwv_flow_imp.g_varchar2_table(714) := '70652E627573793D66756E6374696F6E28297B72657475726E5B226F70656E696E67222C22636F756E74646F776E222C227265636F7264696E67222C22706175736564222C2273746F7070696E67222C22726576696577222C2275706C6F6164696E6722';
wwv_flow_imp.g_varchar2_table(715) := '5D2E696E6465784F6628746869732E7374617465293E3D307D2C632E70726F746F747970652E73657444697361626C65643D66756E6374696F6E2874297B696628746869732E64697361626C65643D2121742C742626746869732E627573792829262674';
wwv_flow_imp.g_varchar2_table(716) := '6869732E7374617465213D3D2275706C6F6164696E6722297B696628746869732E726563297B746869732E7265632E6F6E73746F703D6E756C6C3B7472797B746869732E7265632E73746F7028297D63617463687B7D746869732E7265633D6E756C6C7D';
wwv_flow_imp.g_varchar2_table(717) := '636C656172496E74657276616C28746869732E7469636B292C636C656172496E74657276616C28746869732E636454696D6572292C746869732E63616E63656C6C65643D21302C746869732E73747441626F727428292C746869732E72656C6561736528';
wwv_flow_imp.g_varchar2_table(718) := '292C746869732E636C65617252657669657728292C746869732E73746174653D2269646C65227D746869732E72656E6465724C69737428292C746869732E73796E6328297D3B66756E6374696F6E206D6528742C65297B747970656F6620653D3D226675';
wwv_flow_imp.g_varchar2_table(719) := '6E6374696F6E22262628743D652874297C7C74292C742E746578747326266E742E657874656E642841742C742E7465787473293B76617220693D6E657720632874292C6E3D692E696E7075743B6D745B742E6974656D5D3D692C692E726F6F742E736574';
wwv_flow_imp.g_varchar2_table(720) := '4174747269627574652822646174612D7374617465222C2269646C6522292C617065782E6974656D2E63726561746528742E6974656D2C7B67657456616C75653A66756E6374696F6E28297B72657475726E206E2E76616C75657D2C73657456616C7565';
wwv_flow_imp.g_varchar2_table(721) := '3A66756E6374696F6E2873297B692E73657456616C75652873297D2C69734368616E6765643A66756E6374696F6E28297B72657475726E206E2E76616C7565213D3D692E696E697469616C7C7C692E6275737928297D2C656E61626C653A66756E637469';
wwv_flow_imp.g_varchar2_table(722) := '6F6E28297B692E73657444697361626C6564282131297D2C64697361626C653A66756E6374696F6E28297B692E73657444697361626C6564282130297D2C697344697361626C65643A66756E6374696F6E28297B72657475726E20692E64697361626C65';
wwv_flow_imp.g_varchar2_table(723) := '647D2C736574466F637573546F3A66756E6374696F6E28297B72657475726E206E7428692E726F6F74292E66696E642822627574746F6E3A76697369626C653A656E61626C656422292E666972737428297D2C646973706C617956616C7565466F723A66';
wwv_flow_imp.g_varchar2_table(724) := '756E6374696F6E28297B72657475726E20692E6974656D732E6D61702866756E6374696F6E2873297B72657475726E20732E6E616D657D292E6A6F696E28222C2022297D7D297D72657475726E206E7428646F63756D656E74292E6F6E28226170657862';
wwv_flow_imp.g_varchar2_table(725) := '65666F7265706167657375626D6974222C66756E6374696F6E28742C65297B4F626A6563742E6B657973286D74292E666F72456163682866756E6374696F6E2869297B766172206E3D6D745B695D2C733D537472696E67286E2E6366672E616C6C6F7752';
wwv_flow_imp.g_varchar2_table(726) := '657175657374737C7C2222292E746F55707065724361736528292E73706C6974282F5B5C732C3A5D2B2F293B696628212821646F63756D656E742E626F64792E636F6E7461696E73286E2E726F6F74297C7C216E2E62757379282929297B696628652626';
wwv_flow_imp.g_varchar2_table(727) := '732E696E6465784F6628537472696E672865292E746F5570706572436173652829293E3D30297B7472797B73657373696F6E53746F726167652E7365744974656D28226D706C75732D6E6F64726166743A222B6E2E64726166744B65792C223122297D63';
wwv_flow_imp.g_varchar2_table(728) := '617463687B7D6E2E64726F70447261667428293B72657475726E7D617065782E6576656E742E6743616E63656C466C61673D21302C6E2E736179286F28224255535922292C227761726E22292C617065782E6D6573736167652E636C6561724572726F72';
wwv_flow_imp.g_varchar2_table(729) := '7328292C617065782E6D6573736167652E73686F774572726F7273285B7B747970653A226572726F72222C6C6F636174696F6E3A2270616765222C6D6573736167653A286E2E6366672E6C6162656C3F6E2E6366672E6C6162656C2B223A20223A222229';
wwv_flow_imp.g_varchar2_table(730) := '2B6F28224255535922292C756E736166653A21317D5D297D7D297D292C7B76657273696F6E3A4A742C696E69743A6D652C707265736574733A62742C74657874733A41742C6669785765626D3A5F742C6669784D70343A48742C6765743A66756E637469';
wwv_flow_imp.g_varchar2_table(731) := '6F6E2874297B76617220653D6D745B745D3B72657475726E206526267B73746172743A66756E6374696F6E28297B652E737461727428297D2C70617573653A66756E6374696F6E28297B652E706175736528297D2C726573756D653A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(732) := '28297B652E726573756D6528297D2C73746F703A66756E6374696F6E28297B652E73746F7028297D2C636170747572653A66756E6374696F6E28297B652E6361707475726528297D2C6B696E643A66756E6374696F6E2869297B72657475726E20692626';
wwv_flow_imp.g_varchar2_table(733) := '652E7365744B696E642869292C652E6B696E647D2C7573653A66756E6374696F6E28297B652E61636365707428297D2C646973636172643A66756E6374696F6E28297B652E64697363617264282131297D2C73746174653A66756E6374696F6E28297B72';
wwv_flow_imp.g_varchar2_table(734) := '657475726E20652E73746174657D2C6973427573793A66756E6374696F6E28297B72657475726E20652E6275737928297D2C7265636F7264696E67733A66756E6374696F6E28297B72657475726E20652E6974656D732E6D61702866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(735) := '69297B72657475726E7B7365713A692E7365712C6E616D653A692E6E616D652C6D696D65547970653A692E6D696D652C6B696E643A692E6B696E642C62797465733A692E73697A652C7365636F6E64733A692E6475726174696F6E2C77696474683A692E';
wwv_flow_imp.g_varchar2_table(736) := '77696474682C6865696768743A692E6865696768742C7472616E7363726970743A692E7472616E7363726970747D7D297D7D7D7D7D28617065782E6A5175657279293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(12126018887789008)
,p_plugin_id=>wwv_flow_imp.id(12115540231788950)
,p_file_name=>'js/mediaPlus.min.js'
,p_mime_type=>'application/javascript'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
