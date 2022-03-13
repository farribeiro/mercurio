# Pinned ghcr.io/ronoaldo/minetestserver:stable-5 release
FROM ghcr.io/ronoaldo/minetestserver@sha256:ba5a3af29f086d94339f5bada2d7374c97ff1347896fec216e3e1f54206f8a65

# Setup system-wide settings
USER root
RUN mkdir -p /var/lib/mercurio &&\
    mkdir -p /var/lib/minetest/.minetest &&\
    chown -R minetest /var/lib/mercurio /var/lib/minetest /etc/minetest
# Install mods system-wide (ro)
RUN mkdir -p /usr/share/minetest/mods &&\
    cd /usr/share/minetest &&\
    contentdb install --debug --url=https://contentdb.ronoaldo.net \
        apercy/airutils@11252 \
        apercy/kartcar@10587 \
        apercy/trike@11084 \
        apercy/hidroplane@11294 \
        apercy/motorboat@10996 \
        apercy/demoiselle@11065 \
        apercy/supercub@11295 \
        apercy/automobiles_pck@11425 \
        AiTechEye/smartshop@903 \
        BuckarooBanzay/mapserver@10938 \
        bell07/carpets@3671 \
        bell07/skinsdb@11044 \
        Calinou/moreblocks@8247 \
        Calinou/moreores@8248 \
        cronvel/respawn@2406 \
        Dragonop/tools_obsidian@6102 \
        Don/mydoors@222 \
        ElCeejo/draconis@11512 \
        ElCeejo/creatura@11412 \
        FaceDeer/anvil@5696 \
        FaceDeer/hopper@6074 \
        Gundul/water_life@10254 \
        "Hybrid Dog/we_undo@9288" \
        JAstudios/moreswords@9585 \
        Jeija/digilines@8574 \
        Jeija/mesecons@11304 \
        joe7575/lumberjack@11039 \
        joe7575/tubelib2@10505 \
        jp/xdecor@10178 \
        Liil/nativevillages@7404 \
        Liil/people@6771 \
        Linuxdirk/mtimer@9958 \
        Lokrates/biofuel@5970 \
        Lone_Wolf/headanim@8888 \
        MeseCraft/void_chest@5565 \
        mt-mods/travelnet@8497 \
        neko259/telegram@6870 \
        philipmi/regrowing_fruits@10631 \
        Piezo_/illumination@1091 \
        Piezo_/hangglider@ \
        PilzAdam/nether@11303 \
        RealBadAngel/unified_inventory@10829 \
        rael5/nether_mobs@6364 \
        rnd/basic_machines@58 \
        rubenwardy/awards@6092 \
        ShadowNinja/areas@5030 \
        Shara/abriglass@32 \
        sfan5/worldedit@9572 \
        sofar/crops@176 \
        sofar/emote@1317 \
        Sokomine/markers@306 \
        Sokomine/replacer@76 \
        stu/3d_armor@11131 \
        TenPlus1/bakedclay@9438 \
        TenPlus1/bonemeal@10585 \
        TenPlus1/dmobs@11181 \
        TenPlus1/ethereal@11207 \
        TenPlus1/farming@10944 \
        TenPlus1/itemframes@10483 \
        TenPlus1/mob_horse@11324 \
        TenPlus1/mobs@11107 \
        TenPlus1/mobs_animal@10737 \
        TenPlus1/mobs_monster@10752 \
        TenPlus1/mobs_npc@10750 \
        TenPlus1/protector@11106 \
        Termos/mobkit@6391 \
        Traxie21/tpr@8314 \
        VanessaE/basic_materials@10975 \
        VanessaE/basic_signs@7503 \
        VanessaE/currency@10265 \
        VanessaE/homedecor_modpack@11314 \
        VanessaE/home_workshop_modpack@9914 \
        VanessaE/unifieddyes@7577 \
        VanessaE/signs_lib@11166 \
        Wuzzy/calendar@5062 \
        Wuzzy/hbarmor@1275 \
        Wuzzy/hbhunger@9156 \
        Wuzzy/hudbars@8390 \
        Wuzzy/inventory_icon@469 \
        Wuzzy/show_wielded_item@7596 \
        Wuzzy/tsm_pyramids@3355 \
        x2048/cinematic@7122
# Install mods from git when not available elsewhere
RUN apt-get update && apt-get install git -yq && apt-get clean && git config --global advice.detachedHead false &&\
    cd /usr/share/minetest/mods &&\
    git clone --depth=1 https://github.com/ronoaldo/aviator --branch="V1.6" &&\
    git clone --depth=1 https://github.com/ronoaldo/filler --branch="git20180215" &&\
    git clone --depth=1 https://github.com/ronoaldo/minenews --branch="v1.0.0" &&\
    git clone --depth=1 https://github.com/ronoaldo/patron --branch="v1.0.0" &&\
    git clone --depth=1 https://github.com/ronoaldo/extra_doors --branch="v1.0.0-mercurio" &&\
    git clone --depth=1 https://github.com/ronoaldo/x_bows --branch="v1.0.5" &&\
    git clone --depth=1 https://github.com/ronoaldo/hbsprint --branch="v1.0.0-mercurio" &&\
    git clone --depth=1 https://github.com/ronoaldo/ju52 --branch="git20211207" &&\
    git clone --depth=1 https://github.com/ronoaldo/helicopter --branch="before" &&\
    git clone --depth=1 https://github.com/ronoaldo/techpack --branch="v2.02-mercurio" &&\
    git clone --depth=1 https://github.com/ronoaldo/drawers --branch="v0.6.3-mercurio" &&\
    git clone --depth=1 https://github.com/ronoaldo/xtraores --branch="v0.22-mercurio2"
# Add server skins to database
COPY skins/meta     /usr/share/minetest/mods/skinsdb/meta
COPY skins/textures /usr/share/minetest/mods/skinsdb/textures
# Add server mod
COPY ./mercurio /usr/share/minetest/mods/mercurio
# Add configuration files to image
COPY world.mt      /etc/minetest/world.mt
COPY minetest.conf /etc/minetest/minetest.conf
COPY mercurio.sh   /usr/bin
COPY backup.sh     /usr/bin
# Restore user to minetest and redefine launch script
USER minetest
CMD ["/usr/bin/mercurio.sh"]
