FROM kong/kong:3.4.0

USER root

LABEL authors="Cristian Chiru <cristian.chiru@revomatico.com>"
RUN rm -rf ~/.luarocks

ENV DEV_PACKAGES="libssl-dev make gcc git curl unzip" \
    LUA_BASE_DIR="/usr/local/share/lua/5.1" \
    KONG_PLUGIN_OIDC_VER="1.4.0-1" \
    KONG_PLUGIN_COOKIES_TO_HEADERS_VER="1.2.0-1" \
    LUA_RESTY_OIDC_VER="1.7.6-3" \
    NGX_DISTRIBUTED_SHM_VER="1.0.8"

RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y $DEV_PACKAGES \
    && apt-get install -y git \
    ## Install plugins
    # Download ngx-distributed-shm dshm library
    && curl -sL https://raw.githubusercontent.com/grrolland/ngx-distributed-shm/${NGX_DISTRIBUTED_SH    # Remove current lua-resty-sessionresty/dshm.lua \
    && luarocks remove --force lua-resty-session \
    # Add Pluggable Compressors dependencies
    && luarocks install lua-ffi-zlib \
    && luarocks install penlight \
#    && curl -sL https://raw.githubusercontent.com/mrliputo/kong-plugin-xml-json-transformer/v0.2.0-#/kong-psed -E -e 's/(tag =)[^,]+/\1 "'v0.2.0-1'"/' | \
#       tee kong-plugin-xml-json-transformer-0.2.0-1.rockspec \
 #   && luarocks build kong-plugin-xml-json-transformer-0.2.0-1.rockspec \
    # Build kong-oidc from forked repo because is not keeping up with lua-resty-openidc
    && curl -sL https://raw.githubusercontent.com/revomatico/kong-oidc/v${KONG_PLUGIN_OIDC_VER}/kong-oidc.rosed -E -e 's/(tag =)[^,]+/\1 "'v${KONG_PLUGIN_OIDC_VER}'"/' -e "s/(lua-resty-openidc ~>)[^\"]+/\1 ${tee kong-oidc-${KONG_PLUGIN_OIDC_VER}.rockspec \
    && luarocks build kong-oidc-${KONG_PLUGIN_OIDC_VER}.rockspec \
    # Build kong-plugin-cookies-to-headers
    && curl -sL https://raw.githubusercontent.com/revomatico/kong-plugin-cookies-to-headers/${KONG_PLUGI&& luarocks build kong-plugin-cookies-to-headers-${KONG_PLUGIN_COOKIES_TO_HEADERS_VER}.rockspec     # Patch nginx_kong.lua for kong-oidc session_secret                                       [ Read^G H&& TPL=${LUA_BASE_DIR}/kong/templates/nginx_kong.lua \          ^T Execute       ^C Location   ^    # May cause side effects when using another nginx under this kong, unless set to the same value   M-&& sed -i '/server_name kong;/a\ \n\                                                           M-6 Cset \$session_secret "\${{X_SESSION_SECRET}}";\n\                                              ^
    ' "$TPL" \
    # Patch nginx_kong.lua to set dictionaries
    && sed -i -E '/^lua_shared_dict kong\s+.+$/i\ \n\
variables_hash_max_size 2048;\n\
lua_shared_dict discovery \${{X_OIDC_CACHE_DISCOVERY_SIZE}};\n\
lua_shared_dict jwks \${{X_OIDC_CACHE_JWKS_SIZE}};\n\
lua_shared_dict introspection \${{X_OIDC_CACHE_INTROSPECTION_SIZE}};\n\
> if x_session_storage == "shm" then\n\
lua_shared_dict \${{X_SESSION_SHM_STORE}} \${{X_SESSION_SHM_STORE_SIZE}};\n\
> end\n\
map \$remote_addr \$log_ip {\n\
> if x_nolog_list_file then\n\
    include \${{X_NOLOG_LIST_FILE}};\n\
> end\n\
    default 1;\n\
}\n\
' "$TPL" \
    # Patch nginx_kong.lua to add for memcached sessions
    && sed -i "/server_name kong;/a\ \n\
## Session:
    set \$session_storage \${{X_SESSION_STORAGE}};\n\
    set \$session_name \${{X_SESSION_NAME}};\n\
    set \$session_compressor \${{X_SESSION_COMPRESSOR}};\n\
## Session: Memcached specific
    set \$session_memcache_connect_timeout \${{X_SESSION_MEMCACHE_CONNECT_TIMEOUT}};\n\
    set \$session_memcache_send_timeout \${{X_SESSION_MEMCACHE_SEND_TIMEOUT}};\n\
    set \$session_memcache_read_timeout \${{X_SESSION_MEMCACHE_READ_TIMEOUT}};\n\
    set \$session_memcache_prefix \${{X_SESSION_MEMCACHE_PREFIX}};\n\
    set \$session_memcache_host \${{X_SESSION_MEMCACHE_HOST}};\n\
    set \$session_memcache_port \${{X_SESSION_MEMCACHE_PORT}};\n\
    set \$session_memcache_uselocking \${{X_SESSION_MEMCACHE_USELOCKING}};\n\
    set \$session_memcache_spinlockwait \${{X_SESSION_MEMCACHE_SPINLOCKWAIT}};\n\
    set \$session_memcache_maxlockwait \${{X_SESSION_MEMCACHE_MAXLOCKWAIT}};\n\
    set \$session_memcache_pool_timeout \${{X_SESSION_MEMCACHE_POOL_TIMEOUT}};\n\
    set \$session_memcache_pool_size \${{X_SESSION_MEMCACHE_POOL_SIZE}};\n\
## Session: DHSM specific
    set \$session_dshm_region \${{X_SESSION_DSHM_REGION}};\n\
    set \$session_dshm_connect_timeout \${{X_SESSION_DSHM_CONNECT_TIMEOUT}};\n\
    set \$session_dshm_send_timeout \${{X_SESSION_DSHM_SEND_TIMEOUT}};\n\
    set \$session_dshm_read_timeout \${{X_SESSION_DSHM_READ_TIMEOUT}};\n\
    set \$session_dshm_host \${{X_SESSION_DSHM_HOST}};\n\
    set \$session_dshm_port \${{X_SESSION_DSHM_PORT}};\n\
    set \$session_dshm_pool_name \${{X_SESSION_DSHM_POOL_NAME}};\n\
    set \$session_dshm_pool_timeout \${{X_SESSION_DSHM_POOL_TIMEOUT}};\n\
    set \$session_dshm_pool_size \${{X_SESSION_DSHM_POOL_SIZE}};\n\
    set \$session_dshm_pool_backlog \${{X_SESSION_DSHM_POOL_BACKLOG}};\n\
## Session: SHM Specific
    set \$session_shm_store \${{X_SESSION_SHM_STORE}};\n\
    set \$session_shm_uselocking \${{X_SESSION_SHM_USELOCKING}};\n\
    set \$session_shm_lock_exptime \${{X_SESSION_SHM_LOCK_EXPTIME}};\n\
    set \$session_shm_lock_timeout \${{X_SESSION_SHM_LOCK_TIMEOUT}};\n\
    set \$session_shm_lock_step \${{X_SESSION_SHM_LOCK_STEP}};\n\
    set \$session_shm_lock_ratio \${{X_SESSION_SHM_LOCK_RATIO}};\n\
    set \$session_shm_lock_max_step \${{X_SESSION_SHM_LOCK_MAX_STEP}};\n\
" "$TPL" \
    # Patch kong_defaults.lua to add custom variables that are replaced dynamically in the template abov&& TPL=${LUA_BASE_DIR}/kong/templates/kong_defaults.lua \
    && sed -E -i "s/((admin|proxy)_access_log.+)/\1 combined if=\$log_ip/" "$TPL" \
    && sed -i "/\]\]/i\ \n\
x_session_storage = cookie\n\
x_session_name = oidc_session\n\
x_session_compressor = 'none'\n\
x_session_secret = ''\n\
\n\
x_session_memcache_prefix = oidc_sessions\n\
x_session_memcache_connect_timeout = '1000'\n\
x_session_memcache_send_timeout = '1000'\n\
x_session_memcache_read_timeout = '1000'\n\
x_session_memcache_host = memcached\n\
x_session_memcache_port = '11211'\n\
x_session_memcache_uselocking = 'off'\n\
x_session_memcache_spinlockwait = '150'\n\
x_session_memcache_maxlockwait = '30'\n\
x_session_memcache_pool_timeout = '1000'\n\
x_session_memcache_pool_size = '10'\n\
\n\
x_session_dshm_region = oidc_sessions\n\
x_session_dshm_connect_timeout = '1000'\n\
x_session_dshm_send_timeout = '1000'\n\
x_session_dshm_read_timeout = '1000'\n\
x_session_dshm_host = hazelcast\n\
x_session_dshm_port = '4321'\n\
x_session_dshm_pool_name = oidc_sessions\n\
x_session_dshm_pool_timeout = '1000'\n\
x_session_dshm_pool_size = '10'\n\
x_session_dshm_pool_backlog = '10'\n\
\n\
x_session_shm_store_size = 5m\n\
x_session_shm_store = oidc_sessions\n\
x_session_shm_uselocking = off\n\
x_session_shm_lock_exptime = '30'\n\
x_session_shm_lock_timeout = '5'\n\
x_session_shm_lock_step = '0.001'\n\
x_session_shm_lock_ratio = '2'\n\
x_session_shm_lock_max_step = '0.5'\n\
x_session_shm_lock_max_step = '0.5'\n\
\n\
x_oidc_cache_discovery_size = 128k\n\
x_oidc_cache_jwks_size = 128k\n\
x_oidc_cache_introspection_size = 128k\n\
\n\
x_nolog_list_file =\n\
\n\
" "$TPL" \
    && luarocks install xml2lua 1.4 \
    ## Cleanup
    && rm -fr *.rock* \
    # && rm -f /usr/local/openresty/nginx/modules/ngx_wasm_module.so \
    && apt-get purge -y $DEV_PACKAGES \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt \
    ## Create kong and working directory (https://github.com/Kong/kong/issues/2690)
    && mkdir -p /usr/local/kong \
    && chown -R kong:`id -gn kong` /usr/local/kong
#RUN luarocks install kong-plugin-xml-to-json
ENV KONG_PLUGINS_DIR /usr/local/share/lua/5.1/kong/plugins
RUN mkdir -p $KONG_PLUGINS_DIR/xml-json-transformer
RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y $DEV_PACKAGES \
    && apt-get install -y git
# Clone plugin dari GitHub
# Clone plugin dari GitHub
RUN git clone https://github.com/mrliputo/kong-plugin-xml-json-transformer.git /tmp/kong-plugin-xml-json&& cd tmp \r \
#    && cd .. \
#    && cd tmp \
    && cd kong-plugin-xml-json-transformer \
    && git pull \
    && luarocks build kong-plugin-xml-json-transformer-0.2.0-1.rockspec \
    && cd .. \
    && cd ..


# Pindahkan plugin ke dalam direktori plugin Kong
#RUN cp -a /tmp/kong-plugin-xml-json-transformer/kong/plugins/xml-json-transformer/* $KONG_PLUGINS_DIR/xml-json-transformer/
# Hapus sumber kode yang tidak lagi diperlukan
RUN rm -rf /tmp/kong-plugin-xml-json-transformer
USER kong
