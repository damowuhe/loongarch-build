# loongarch-build
build.sh
这是一个智能车龙芯逐飞派的内核kernel和根文件系统rootfs的脚本文件
为了更方便大家使用进行以下变化

1.bulid.sh脚本包含了构建kernel和rootfs两大功能，写到一个build.sh里面生成kernel和rootfs
<img width="884" height="329" alt="0fb674c59e9235197291dcf94fbc8d82" src="https://github.com/user-attachments/assets/3e8452c7-d20e-45c9-8a95-80e015d6abfb" />
<img width="1179" height="301" alt="ef5034df06f06746b1b900339131feb7" src="https://github.com/user-attachments/assets/e84efed0-5e1d-4fdd-bb35-405650c54e02" />

2.镜像输出到表层文件
<img width="385" height="326" alt="dcc7df0cfdae62f74258d511378a8947" src="https://github.com/user-attachments/assets/3a9abc8f-0055-4c38-8724-53c848b6ec97" />

3.可同时清理kernel和rootfs
<img width="811" height="318" alt="193a8bcf51b304737f30efd76b5e8808" src="https://github.com/user-attachments/assets/5c4e539f-91c9-4742-a2fb-4414cc3694ff" />
<img width="1180" height="321" alt="7c2d429f1f9a7d0b62bbdca49cc0425d" src="https://github.com/user-attachments/assets/31b92fd5-562c-4655-9764-e6fd37261bf5" />

4.方便使用menuconfig图形化配置工具，使用脚本命令即可
<img width="837" height="204" alt="56ab52ed341289b600b97dd7c1154f8d" src="https://github.com/user-attachments/assets/4d6d0a7c-8849-4a8b-8b19-c0a8376b893a" />
<img width="1141" height="363" alt="43bf6aabb300ea45d27d3d0da4f4fd3c" src="https://github.com/user-attachments/assets/d7a3187b-7d45-4b9d-ad57-b86b01617f6d" />
<img width="1165" height="362" alt="51d0b9fb78ddcf1f50aec9c336e3ecd1" src="https://github.com/user-attachments/assets/afcac7a3-8fea-48a4-97bb-7b515d9e6152" />
<img width="1165" height="443" alt="d9f6e4babd8bce2fc2eb2ec4da23573d" src="https://github.com/user-attachments/assets/402d002e-dd24-4f38-9965-8a928ac112c4" />

5.通过build.sh可以知道哪些命令可以使用
<img width="607" height="103" alt="0d4081d4b62c54a0bafdbdc00148da93" src="https://github.com/user-attachments/assets/ef30d49b-f63f-4833-ba5a-7fb77a55901f" />

6.可使用build.sh all或者all_clean全部编译或清除
