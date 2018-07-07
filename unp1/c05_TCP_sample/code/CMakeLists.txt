project(TCP_sample)
include_directories("../../Code")
set(LIB_PATH "../../Code")
set(BASE_C ${LIB_PATH}/unp_base.c)

add_executable(server server.c ${BASE_C})
add_executable(client client.c ${BASE_C})

add_executable(server_good server_good.c ${BASE_C})
add_executable(server_tst server_tst.c ${BASE_C})
