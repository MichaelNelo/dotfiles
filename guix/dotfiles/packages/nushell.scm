(define-module (dotfiles packages nushell)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages c)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages sqlite)
  #:use-module (srfi srfi-1)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (ice-9 match)
  #:export (nushell-0.104.0))

;; Override nushell to version 0.104.0 (required by oh-my-posh >= 2025.1.1)
;; We define 0.104.0 crate-sources for all nu-* crates and replace the
;; 0.103.0 versions from cargo-inputs.

(define (rust-nu-source name version hash)
  "Return a crate-source for a nu-* crate."
  (crate-source name version hash))

(define (to-replace? key)
  "Return a predicate that matches origins by KEY.
KEY is either a string NAME (replace any version of NAME) or a pair
(NAME . VERSION) (replace only NAME at VERSION, for surgical swaps when
multiple versions coexist).
The crates.io download URI has the form .../crates/NAME/VERSION/download,
so we anchor on the surrounding slashes to avoid matching crates that merely
end in NAME (e.g. \"mio\" matching \"signal-hook-mio\")."
  (lambda (origin)
    (let ((uri (origin-uri origin)))
      (and (string? uri)
           (if (pair? key)
               (string-contains uri
                                (string-append "/" (car key)
                                               "/" (cdr key) "/"))
               (string-contains uri (string-append "/" key "/")))))))

;; ============================================================
;; nu-* crates (all 0.104.0)
;; ============================================================

(define rust-nu-cli-0.104.0
  (rust-nu-source "nu-cli" "0.104.0"
                  "137641z944291cazhivcj8y4a7db1qzzpgihwysznpkhb561sm26"))

(define rust-nu-cmd-base-0.104.0
  (rust-nu-source "nu-cmd-base" "0.104.0"
                  "15nxcq8alzdc7060x33j7raz54ypjk6igwm33k2wcr3yc0jkbr8s"))

(define rust-nu-cmd-extra-0.104.0
  (rust-nu-source "nu-cmd-extra" "0.104.0"
                  "096kxypy7bwz9j820rzkqv9hqslsnaiyy034llshskjvlz3mnfk1"))

(define rust-nu-cmd-lang-0.104.0
  (rust-nu-source "nu-cmd-lang" "0.104.0"
                  "1zmfcxc09cp3x0q9r2lqpz198flbdsg8s1jxnay2g3lgm3nxysp6"))

(define rust-nu-cmd-plugin-0.104.0
  (rust-nu-source "nu-cmd-plugin" "0.104.0"
                  "14qsaay0gg3jn4n67ywdwk1gpibwl4gjhh4mmvl45fdizca30yyp"))

(define rust-nu-color-config-0.104.0
  (rust-nu-source "nu-color-config" "0.104.0"
                  "137x1xpzxdz6xy2khzv5875gc4cwhiihr0i8gwwgg4yb3nwlm14f"))

(define rust-nu-command-0.104.0
  (rust-nu-source "nu-command" "0.104.0"
                  "0r7bzifhjdyriz88w0m04x7hvnbj62p1p440b96zzr0pvmyr7cwa"))

(define rust-nu-derive-value-0.104.0
  (rust-nu-source "nu-derive-value" "0.104.0"
                  "0vwb0glf08hwvksm9yrfwynnp0pa18c7yqafzq0hsi5nb3ixil2z"))

(define rust-nu-engine-0.104.0
  (rust-nu-source "nu-engine" "0.104.0"
                  "1iw7snr8fl36s1arr84w67xjdp5nhdxdmh7hfl1lc29x7r402aqc"))

(define rust-nu-explore-0.104.0
  (rust-nu-source "nu-explore" "0.104.0"
                  "0nx4l5qwbp3nwg6l0ql2nahzhpq0bglyc3g7v54adm1hdgzrx3w5"))

(define rust-nu-glob-0.104.0
  (rust-nu-source "nu-glob" "0.104.0"
                  "0r43vd3hsl1k0pbwv4lqzlapq5771m79vri4xbpn2q1ki5cf4b10"))

(define rust-nu-json-0.104.0
  (rust-nu-source "nu-json" "0.104.0"
                  "04lb82lvy5wk1h6jy2rk59vfl24ygfbly9cpxi1d775v0ixci03f"))

(define rust-nu-lsp-0.104.0
  (rust-nu-source "nu-lsp" "0.104.0"
                  "1528jb4wfm3n7bivvhz8ym0mi2fa823x0ff7ll09ycw1i377azwd"))

(define rust-nu-parser-0.104.0
  (rust-nu-source "nu-parser" "0.104.0"
                  "1na9bkh2d5ky0v5ax71dxh1hpmyjixyx3nb3129w32a99ppr21fb"))

(define rust-nu-path-0.104.0
  (rust-nu-source "nu-path" "0.104.0"
                  "0n42bickl5srs7kiqc4gmjw1qrjr6yk8s0qhkx65r2l90ry8rij1"))

(define rust-nu-plugin-core-0.104.0
  (rust-nu-source "nu-plugin-core" "0.104.0"
                  "152fz6qvq4ymj0j3vbrh2rm32h2k1q57890rzigr4qibvvk1dr1h"))

(define rust-nu-plugin-engine-0.104.0
  (rust-nu-source "nu-plugin-engine" "0.104.0"
                  "0ap80wfibqdkysk7czcd8ci0jqnmiilf19drc7zfna9ql95j3yql"))

(define rust-nu-plugin-protocol-0.104.0
  (rust-nu-source "nu-plugin-protocol" "0.104.0"
                  "018325wcnn5p2bvvjj373a0c1l3r1mk890ay1cajkfsiwkgdnzmy"))

(define rust-nu-pretty-hex-0.104.0
  (rust-nu-source "nu-pretty-hex" "0.104.0"
                  "0r4q9nz0kazl2z236xnh66ws5d9ix5vd97jnlzq4l7g515xkllk4"))

(define rust-nu-protocol-0.104.0
  (rust-nu-source "nu-protocol" "0.104.0"
                  "1av0gkg67g6446p6da8091m76i0p67x11cic0p2x7ypi8wcpnrdb"))

(define rust-nu-std-0.104.0
  (rust-nu-source "nu-std" "0.104.0"
                  "1pnfbk62j4gbng01p7p9lb8r4cnjmq2z2p57jwnc6s4hazsbrvbr"))

(define rust-nu-system-0.104.0
  (rust-nu-source "nu-system" "0.104.0"
                  "0yjpd5bcjglnjph4m5kzj3gapz2h5bc0014nqf33l7jgmfm98w7l"))

(define rust-nu-table-0.104.0
  (rust-nu-source "nu-table" "0.104.0"
                  "0i6gcskaxmgfyh3z5gymh43kyrw879g720kfpsv5xsgmqasw2j12"))

(define rust-nu-term-grid-0.104.0
  (rust-nu-source "nu-term-grid" "0.104.0"
                  "0df72bhpsc77rwidhs5qchhd54l55m52ngr2xyjja7bdbqjabb22"))

(define rust-nu-test-support-0.104.0
  (rust-nu-source "nu-test-support" "0.104.0"
                  "0c76gbcp0d740m5srrc7zrgds82haw37cqnhma12q92ss8pr76cp"))

(define rust-nu-utils-0.104.0
  (rust-nu-source "nu-utils" "0.104.0"
                  "108l3wjj7y7ba9jip5xqkz2lg00s58qkvhv8dcd312ypfjvrjy9j"))

(define rust-nuon-0.104.0
  (rust-nu-source "nuon" "0.104.0"
                  "19d9in7mqllj2m6d1qc1w9h83a5yv46c8f1x90h89mbywgz5blba"))

;; ============================================================
;; External crates that changed versions
;; ============================================================

(define rust-reedline-0.40.0
  (rust-nu-source "reedline" "0.40.0"
                  "02yms8lpz2179bwz27jlx0y5s80qhmj2hj76dkxyn4sd96vzmkdm"))

(define rust-shadow-rs-1.1.1
  (rust-nu-source "shadow-rs" "1.1.1"
                  "19ji8sj63jipfv80sv5v9vf2cml1r9x4hzaya1z6vxlwc3njamkd"))

(define rust-calamine-0.27.0
  (rust-nu-source "calamine" "0.27.0"
                  "1jwc6hfy52ia0bvnxzn4zwrgn9nw95nk8qky0awhd0n6lldzi03d"))

(define rust-data-encoding-2.9.0
  (rust-nu-source "data-encoding" "2.9.0"
                  "0xm46371aw613ghc12ay4vsnn49hpcmcwlijnqy8lbp2bpd308ra"))

(define rust-human-date-parser-0.3.1
  (rust-nu-source "human-date-parser" "0.3.1"
                  "03hiqw8yxsi6ps0fzmykqghc08pszsjfjap57ccckcp4dp2q6vs0"))

(define rust-arrayvec-0.7.6
  (rust-nu-source "arrayvec" "0.7.6"
                  "0l1fz4ccgv6pm609rif37sl5nv5k6lbzi7kkppgzqzh1vwix20kw"))

(define rust-bitflags-2.6.0
  (rust-nu-source "bitflags" "2.6.0"
                  "1pkidwzn3hnxlsl8zizh0bncgbjnw7c41cx7bby26ncbzmiznj5h"))

(define rust-bytesize-1.3.3
  (rust-nu-source "bytesize" "1.3.3"
                  "0nb645ma48nwsv1piylzcza0avjp435sl8krhyws3q18kv5ap4rf"))

(define rust-crossbeam-channel-0.5.15
  (rust-nu-source "crossbeam-channel" "0.5.15"
                  "1cicd9ins0fkpfgvz9vhz3m9rpkh6n8d3437c3wnfsdkd3wgif42"))

(define rust-getrandom-0.3.1
  (rust-nu-source "getrandom" "0.3.1"
                  "1y154yzby383p63ndw6zpfm0fz3vf6c0zdwc7df6vkl150wrr923"))

(define rust-hashbrown-0.15.2
  (rust-nu-source "hashbrown" "0.15.2"
                  "12dj0yfn59p3kh3679ac0w1fagvzf4z2zp87a13gbbqbzw0185dz"))

(define rust-indexmap-2.9.0
  (rust-nu-source "indexmap" "2.9.0"
                  "07m15a571yywmvqyb7ms717q9n42b46badbpsmx215jrg7dhv9yf"))

(define rust-is-debug-1.1.0
  (rust-nu-source "is_debug" "1.1.0"
                  "01yl28nv69wsqiyyhfbgx52yskpjyw5z4xq137c33ja3wb96dqhz"))

(define rust-itertools-0.13.0
  (rust-nu-source "itertools" "0.13.0"
                  "11hiy3qzl643zcigknclh446qb9zlg4dpdzfkjaa9q9fqpgyfgj1"))

(define rust-mio-1.0.3
  (rust-nu-source "mio" "1.0.3"
                  "1gah0h4ia3avxbwym0b6bi6lr6rpysmj9zvw6zis5yq0z0xq91i8"))

(define rust-nix-0.29.0
  (rust-nu-source "nix" "0.29.0"
                  "0ikvn7s9r2lrfdm3mx1h7nbfjvcc6s9vxdzw7j5xfkd2qdnp9qki"))

(define rust-nom-8.0.0
  (rust-nu-source "nom" "8.0.0"
                  "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz"))

(define rust-openssl-0.10.72
  (rust-nu-source "openssl" "0.10.72"
                  "1np54pm6hw512rmfjv3kc54h8yvf51mdlm8a8cc33xx1b1yympzy"))

(define rust-openssl-sys-0.9.107
  (rust-nu-source "openssl-sys" "0.9.107"
                  "01yydv8yaagdnapvair8b6rggf225lwb854h99s9qx44rnd9g242"))

(define rust-parse-datetime-0.8.0
  (rust-nu-source "parse_datetime" "0.8.0"
                  "1rxiyks9vsz7x3cah1m23gbxkffz7r6r4sbp3ml3zwgbdhax3zsb"))

(define rust-quick-xml-0.37.1
  (rust-nu-source "quick-xml" "0.37.1"
                  "00vagwspb7j87v34ybvylphf9isf8bb5zy9fcgcb91rrzyyjjbzj"))

(define rust-rand-0.9.0
  (rust-nu-source "rand" "0.9.0"
                  "156dyvsfa6fjnv6nx5vzczay1scy5183dvjchd7bvs47xd5bjy9p"))

(define rust-rand-chacha-0.9.0
  (rust-nu-source "rand_chacha" "0.9.0"
                  "1jr5ygix7r60pz0s1cv3ms1f6pd1i9pcdmnxzzhjc3zn3mgjn0nk"))

(define rust-rand-core-0.9.3
  (rust-nu-source "rand_core" "0.9.3"
                  "0f3xhf16yks5ic6kmgxcpv1ngdhp48mmfy4ag82i1wnwh8ws3ncr"))

(define rust-rust-embed-8.7.0
  (rust-nu-source "rust-embed" "8.7.0"
                  "17f4pribh9nd97szi8zzc2a5xd5myxfjwi5vrvvrmfgwa3pc1yz5"))

(define rust-rust-embed-impl-8.7.0
  (rust-nu-source "rust-embed-impl" "8.7.0"
                  "0bkh66kzmqv1i478d24nsv4nf89crhs732lblcy6dxp3lb4iix3b"))

(define rust-rust-embed-utils-8.7.0
  (rust-nu-source "rust-embed-utils" "8.7.0"
                  "08cfp8x1nw1p272128hfwr9fvnlbg7dmafbbs1ji5q3z2jampm88"))

(define rust-syn-2.0.90
  (rust-nu-source "syn" "2.0.90"
                  "0cfg5dsr1x0hl6b9hz08jp1197mx0rq3xydqmqaws36xlms3p7ci"))

(define rust-thiserror-2.0.12
  (rust-nu-source "thiserror" "2.0.12"
                  "024791nsc0np63g2pq30cjf9acj38z3jwx9apvvi8qsqmqnqlysn"))

(define rust-thiserror-impl-2.0.12
  (rust-nu-source "thiserror-impl" "2.0.12"
                  "07bsn7shydaidvyyrm7jz29vp78vrxr9cr9044rfmn078lmz8z3z"))

(define rust-titlecase-3.5.0
  (rust-nu-source "titlecase" "3.5.0"
                  "0dcl4rg82qrkzh7paivvc519cgf8w84m1svd5n9lawjz89yx1ym1"))

(define rust-tokio-1.44.2
  (rust-nu-source "tokio" "1.44.2"
                  "0j4w3qvlcqzgbxlnap0czvspqj6x461vyk1sbqcf97g4rci8if76"))

(define rust-unicode-width-0.2.0
  (rust-nu-source "unicode-width" "0.2.0"
                  "1zd0r5vs52ifxn25rs06gxrgz8cmh4xpra922k0xlmrchib1kj0z"))

(define rust-uucore-0.0.30
  (rust-nu-source "uucore" "0.0.30"
                  "0g96d1zg0vn6nsjk1yr8n9l1wvzm413xb8qiqrwyfvfhfwlfix3i"))

(define rust-uucore-procs-0.0.30
  (rust-nu-source "uucore_procs" "0.0.30"
                  "1r7pn59mamp05x7x9a10483v3dmb2k84isjx48p60bl1ks2ka967"))

(define rust-uu-cp-0.0.30
  (rust-nu-source "uu_cp" "0.0.30"
                  "0iqim6j05xarn934y97c80z3fxsm15h6glsmj18pjvw9nw33jbxz"))

(define rust-uu-mkdir-0.0.30
  (rust-nu-source "uu_mkdir" "0.0.30"
                  "0ml3ykx3p28ail552k1z9ax418rhf2lxfq54pf95pxajv2jmdrav"))

(define rust-uu-mktemp-0.0.30
  (rust-nu-source "uu_mktemp" "0.0.30"
                  "1z0s6mfvkdly091pby18smmqishdwqx47zqrir1yg07lyzsgq1ak"))

(define rust-uu-mv-0.0.30
  (rust-nu-source "uu_mv" "0.0.30"
                  "0jbh5k8p70k05p32xji3a2hrw6yg7rnch9lv0ymggr2lcnwi9qiv"))

(define rust-uu-touch-0.0.30
  (rust-nu-source "uu_touch" "0.0.30"
                  "08549v8h2ik0a54rs52i906vdkwjjnr5l4avywz8xpj508d5hn0y"))

(define rust-uu-uname-0.0.30
  (rust-nu-source "uu_uname" "0.0.30"
                  "1m2dhp8xhv65w50bdpnd6i6icvfim9jsn1j26fz826m93ni9ck9j"))

(define rust-uu-whoami-0.0.30
  (rust-nu-source "uu_whoami" "0.0.30"
                  "0sp9nf9wkqpy7fshqzz3y6gflq1b9yfwvrigy5w5jahpigg59qmy"))

(define rust-uuhelp-parser-0.0.30
  (rust-nu-source "uuhelp_parser" "0.0.30"
                  "1varjjqmg57a6bg7dx4c6qg0ddx2ms08ab85nwy25y40ymrdkdhb"))

(define rust-uuid-1.16.0
  (rust-nu-source "uuid" "1.16.0"
                  "1a9dkv6jm4lz7ip9l9i1mcx7sh389xjsr03l6jgwqjpmkdvpm3s5"))

(define rust-vte-0.11.1
  (rust-nu-source "vte" "0.11.1"
                  "15r1ff4j8ndqj9vsyil3wqwxhhl7jsz5g58f31n0h1wlpxgjn0pm"))

(define rust-wasi-0.13.3
  (rust-nu-source "wasi" "0.13.3+wasi-0.2.2"
                  "1lnapbvdcvi3kc749wzqvwrpd483win2kicn1faa4dja38p6v096"))

(define rust-zerocopy-0.8.23
  (rust-nu-source "zerocopy" "0.8.23"
                  "1inbxgqhsxghawsss8x8517g30fpp8s3ll2ywy88ncm40m6l95zx"))

(define rust-zerocopy-derive-0.8.23
  (rust-nu-source "zerocopy-derive" "0.8.23"
                  "0m7iwisxz111sgkski722nyxv0rixbs0a9iylrcvhpfx1qfw0lk3"))

(define rust-zip-2.5.0
  (rust-nu-source "zip" "2.5.0"
                  "120zjj8rg5fzmvrb1lmznljmkxlcvi7lnmrpdwzy4r2g8qbkih17"))

(define rust-array-init-cursor-0.2.1
  (rust-nu-source "array-init-cursor" "0.2.1"
                  "1hqzgcw4930bp8gw2qy10nfyw7c3kwgwaf5yd2klw7ad487zwlgd"))

(define rust-mockito-1.7.0
  (rust-nu-source "mockito" "1.7.0"
                  "0j5acfmm1ki098rwn63g0swn2f69ljf00x03givybdyr33jf0q3p"))

(define rust-pest-consume-1.1.3
  (rust-nu-source "pest_consume" "1.1.3"
                  "0sskbz2hlqdvrjrp0nxww5diaggsccp2ziql5qaff62xs4178i3r"))

(define rust-pest-consume-macros-1.1.0
  (rust-nu-source "pest_consume_macros" "1.1.0"
                  "0a9zg5zishafz0hhmp2byfd04h22naka0sy1q5739jwrm2kk11lx"))

(define rust-socks-0.3.4
  (rust-nu-source "socks" "0.3.4"
                  "12ymihhib0zybm6n4mrvh39hj1dm0ya8mqnqdly63079kayxphzh"))

(define rust-tz-rs-0.7.0
  (rust-nu-source "tz-rs" "0.7.0"
                  "18bi7k9zgwbm0ch049c1mj901a6aza4mr4z7f0hfg5wkp7r0nig1"))

(define rust-tzdb-0.7.2
  (rust-nu-source "tzdb" "0.7.2"
                  "1xgv84ipra42fvvv8fx5lvqjy0h9w72jbf608ygl95gjarcymqhb"))

(define rust-tzdb-data-0.2.1
  (rust-nu-source "tzdb_data" "0.2.1"
                  "0fw0zyxl0x4qfnqwljyjjn40g0crm5ssr30kvd7pf2ir3xfb6106"))

(define rust-wit-bindgen-rt-0.33.0
  (rust-nu-source "wit-bindgen-rt" "0.33.0"
                  "0g4lwfp9x6a2i1hgjn8k14nr4fsnpd5izxhc75zpi2s5cvcg6s1j"))

(define rust-unicode-width-0.1.11
  (rust-nu-source "unicode-width" "0.1.11"
                  "11ds4ydhg8g7l06rlmh712q41qsrd0j0h00n1jm74kww3kqk65z5"))

(define rust-syn-1.0.109
  (rust-nu-source "syn" "1.0.109"
                  "0ds2if4600bd59wsv7jjgfkayfzy3hnazs394kz6zdkmna8l3dkj"))

(define rust-nix-0.28.0
  (rust-nu-source "nix" "0.28.0"
                  "1r0rylax4ycx3iqakwjvaa178jrrwiiwghcw95ndzy72zk25c8db"))

(define rust-quick-xml-0.32.0
  (rust-nu-source "quick-xml" "0.32.0"
                  "1hk9x4fij5kq1mnn7gmxz1hpv8s9wnnj4gx4ly7hw3mn71c6wfhx"))

(define rust-quick-xml-0.36.2
  (rust-nu-source "quick-xml" "0.36.2"
                  "1zj3sjcjk6sn544wb2wvhr1km5f9cy664vzclygfsnph9mxrlr7p"))

(define rust-atoi-simd-0.16.0
  (rust-nu-source "atoi_simd" "0.16.0"
                  "1sfvqhx7845j9629qhba9b7p71jhkd28agbqxcmi228jjvlgk427"))

(define rust-fast-float2-0.2.3
  (rust-nu-source "fast-float2" "0.2.3"
                  "0mbadcgq221clfpihsfiahizfsgfwk8n3dbgi1fd48vlbi65dszq"))

(define rust-openssl-src-300.4.1
  (rust-nu-source "openssl-src" "300.4.1+3.4.0"
                  "1337svym5imvq9ww04xh0ss38krhbhfb7l92ar5l2qlc2g2fm97s"))

;; ============================================================
;; Crate replacement logic
;; ============================================================

;; Replacements: each entry is (KEY . new-origin).
;; KEY is "NAME" (replaces every version of NAME — only safe when NAME has a
;; single version in cargo-inputs) or (NAME . OLD-VERSION) for surgical
;; replacement when multiple versions coexist and we only swap one.
(define %crate-replacements
  `(;; ---- Single-version bumps (cargo-inputs has one version of NAME). ----
    ("bytesize" . ,rust-bytesize-1.3.3)
    ("calamine" . ,rust-calamine-0.27.0)
    ("crossbeam-channel" . ,rust-crossbeam-channel-0.5.15)
    ("data-encoding" . ,rust-data-encoding-2.9.0)
    ("human-date-parser" . ,rust-human-date-parser-0.3.1)
    ("indexmap" . ,rust-indexmap-2.9.0)
    ("is_debug" . ,rust-is-debug-1.1.0)
    ("nix" . ,rust-nix-0.29.0)
    ("openssl" . ,rust-openssl-0.10.72)
    ("openssl-sys" . ,rust-openssl-sys-0.9.107)
    ("parse_datetime" . ,rust-parse-datetime-0.8.0)
    ("reedline" . ,rust-reedline-0.40.0)
    ("rust-embed" . ,rust-rust-embed-8.7.0)
    ("rust-embed-impl" . ,rust-rust-embed-impl-8.7.0)
    ("rust-embed-utils" . ,rust-rust-embed-utils-8.7.0)
    ("shadow-rs" . ,rust-shadow-rs-1.1.1)
    ("syn" . ,rust-syn-2.0.90)
    ("titlecase" . ,rust-titlecase-3.5.0)
    ("tokio" . ,rust-tokio-1.44.2)
    ("uucore" . ,rust-uucore-0.0.30)
    ("uucore_procs" . ,rust-uucore-procs-0.0.30)
    ("uu_cp" . ,rust-uu-cp-0.0.30)
    ("uu_mkdir" . ,rust-uu-mkdir-0.0.30)
    ("uu_mktemp" . ,rust-uu-mktemp-0.0.30)
    ("uu_mv" . ,rust-uu-mv-0.0.30)
    ("uu_touch" . ,rust-uu-touch-0.0.30)
    ("uu_uname" . ,rust-uu-uname-0.0.30)
    ("uu_whoami" . ,rust-uu-whoami-0.0.30)
    ("uuhelp_parser" . ,rust-uuhelp-parser-0.0.30)
    ("uuid" . ,rust-uuid-1.16.0)
    ("wit-bindgen-rt" . ,rust-wit-bindgen-rt-0.33.0)
    ("zip" . ,rust-zip-2.5.0)
    ;; All nu-* crates bumped 0.103.0 -> 0.104.0.
    ("nu-cli" . ,rust-nu-cli-0.104.0)
    ("nu-cmd-base" . ,rust-nu-cmd-base-0.104.0)
    ("nu-cmd-extra" . ,rust-nu-cmd-extra-0.104.0)
    ("nu-cmd-lang" . ,rust-nu-cmd-lang-0.104.0)
    ("nu-cmd-plugin" . ,rust-nu-cmd-plugin-0.104.0)
    ("nu-color-config" . ,rust-nu-color-config-0.104.0)
    ("nu-command" . ,rust-nu-command-0.104.0)
    ("nu-derive-value" . ,rust-nu-derive-value-0.104.0)
    ("nu-engine" . ,rust-nu-engine-0.104.0)
    ("nu-explore" . ,rust-nu-explore-0.104.0)
    ("nu-glob" . ,rust-nu-glob-0.104.0)
    ("nu-json" . ,rust-nu-json-0.104.0)
    ("nu-lsp" . ,rust-nu-lsp-0.104.0)
    ("nu-parser" . ,rust-nu-parser-0.104.0)
    ("nu-path" . ,rust-nu-path-0.104.0)
    ("nu-plugin-core" . ,rust-nu-plugin-core-0.104.0)
    ("nu-plugin-engine" . ,rust-nu-plugin-engine-0.104.0)
    ("nu-plugin-protocol" . ,rust-nu-plugin-protocol-0.104.0)
    ("nu-pretty-hex" . ,rust-nu-pretty-hex-0.104.0)
    ("nu-protocol" . ,rust-nu-protocol-0.104.0)
    ("nu-std" . ,rust-nu-std-0.104.0)
    ("nu-system" . ,rust-nu-system-0.104.0)
    ("nu-table" . ,rust-nu-table-0.104.0)
    ("nu-term-grid" . ,rust-nu-term-grid-0.104.0)
    ("nu-test-support" . ,rust-nu-test-support-0.104.0)
    ("nu-utils" . ,rust-nu-utils-0.104.0)
    ("nuon" . ,rust-nuon-0.104.0)

    ;; ---- Surgical replacements (cargo-inputs has multiple versions; we ----
    ;; ---- only swap ONE specific old version. The other coexisting    ----
    ;; ---- version from cargo-inputs is preserved untouched.           ----
    (("bitflags" . "2.9.0") . ,rust-bitflags-2.6.0)
    (("getrandom" . "0.3.2") . ,rust-getrandom-0.3.1)
    (("quick-xml" . "0.37.4") . ,rust-quick-xml-0.37.1)
    (("unicode-width" . "0.1.14") . ,rust-unicode-width-0.1.11)
    ;; vte: upstream has 0.10.1 + 0.14.1; 0.104 lock needs 0.10.1 + 0.11.1.
    ;; A transitive Cargo.toml constraint requires ^0.14, so we keep 0.14.1
    ;; and add 0.11.1 as a coexisting third version (see %crate-additions).
    (("wasi" . "0.14.2+wasi-0.2.4") . ,rust-wasi-0.13.3)
    (("zerocopy" . "0.8.24") . ,rust-zerocopy-0.8.23)
    (("zerocopy-derive" . "0.8.24") . ,rust-zerocopy-derive-0.8.23)
    ;; thiserror{,-impl}: cargo-inputs already has 1.0.69 AND 2.0.12 which
    ;; matches what 0.104 needs, so these are no-ops here. Kept as
    ;; documentation in case cargo-inputs is ever rebased onto a snapshot
    ;; that still carries the 2.0.6 line.
    (("thiserror" . "2.0.6") . ,rust-thiserror-2.0.12)
    (("thiserror-impl" . "2.0.6") . ,rust-thiserror-impl-2.0.12)))

;; Additions: origins to append unconditionally. Two cases:
;;   1) Crate is new in 0.104 (no corresponding entry in cargo-inputs).
;;   2) cargo-inputs has only one version of NAME, but 0.104's Cargo.lock
;;      needs TWO versions — we keep cargo-inputs' version intact and add
;;      the second one here.
(define %crate-additions
  (list ;; New crates (no prior entry).
        rust-array-init-cursor-0.2.1
        rust-mockito-1.7.0
        rust-pest-consume-1.1.3
        rust-pest-consume-macros-1.1.0
        rust-socks-0.3.4
        rust-tz-rs-0.7.0
        rust-tzdb-0.7.2
        rust-tzdb-data-0.2.1
        ;; Co-existing second version (cargo-inputs has the other one).
        rust-nix-0.28.0
        rust-nom-8.0.0
        rust-rand-0.9.0
        rust-rand-chacha-0.9.0
        rust-rand-core-0.9.3
        rust-syn-1.0.109
        rust-quick-xml-0.32.0
        rust-quick-xml-0.36.2
        rust-vte-0.11.1
        ;; New transitive deps pulled in by bumped crates (not in upstream).
        rust-atoi-simd-0.16.0    ;; required by calamine 0.27
        rust-fast-float2-0.2.3   ;; required by calamine 0.27
        rust-openssl-src-300.4.1)) ;; required by openssl-sys 0.9.107 vendored feature

(define (rewrite-crate-inputs inputs)
  "Apply %crate-replacements to INPUTS, then append %crate-additions."
  (let ((replaced
         (fold (lambda (replacement acc)
                 (let ((key (car replacement))
                       (new-origin (cdr replacement)))
                   (let ((pred (to-replace? key)))
                     (map (lambda (orig)
                            (if (pred orig) new-origin orig))
                          acc))))
               inputs
               %crate-replacements)))
    (append %crate-additions replaced)))

(define-public nushell-0.104.0
  (package
    (inherit nushell)
    (version "0.104.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "nu" version))
       (file-name (string-append "nu-" version ".tar.gz"))
       (sha256
        (base32 "1g18535icv136i2xwwf2pmk6w6g729gn1xy3ci5wmczq0wb430p1"))))
    (inputs
     (cons* mimalloc openssl sqlite
            (rewrite-crate-inputs (cargo-inputs 'nushell))))))

nushell-0.104.0
