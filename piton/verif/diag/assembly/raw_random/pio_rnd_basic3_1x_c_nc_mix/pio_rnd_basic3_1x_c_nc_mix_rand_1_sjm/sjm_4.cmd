# Modified by Princeton University on June 9th, 2015
# ========== Copyright Header Begin ==========================================
# 
# OpenSPARC T1 Processor File: sjm_4.cmd
# Copyright (c) 2006 Sun Microsystems, Inc.  All Rights Reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES.
# 
# The above named program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License version 2 as published by the Free Software Foundation.
# 
# The above named program is distributed in the hope that it will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this work; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
# 
# ========== Copyright Header End ============================================
CONFIG id=28 iosyncadr=0x7CF00BEEF00
TIMEOUT 10000000
IOSYNC
#==================================================
#==================================================


LABEL_0:

WRITEBLKIO  0x000006120d2cee40 +
        0x341a7b76 0x93e317b8 0xe3b3df3e 0x273216dc +
        0xceb5eb8d 0x87e761bb 0x057f29d2 0xf47bc6e1 +
        0xa3951c44 0x220ddf42 0xa8e0da5c 0x935fd754 +
        0x6ffa6abc 0x5518c955 0xd6eed9a1 0x481e5d99 

WRITEBLKIO  0x00000619e862b780 +
        0x9d3d28b0 0x4e8a906a 0x86a77ca6 0x1c52739c +
        0xeb510cfc 0x75d4f420 0xd5204475 0xdfdc2200 +
        0x577a6c19 0xb50fb2bf 0x9b4eff7f 0xb8b12104 +
        0xd883cfd2 0xaf7d5d00 0x82f2a564 0x2f303a15 

WRITEBLKIO  0x00000606e7c90900 +
        0x539eec02 0x805b029c 0x0cabb5cf 0xa123d6e9 +
        0x53ba9a84 0x9051a82a 0xad1ef0a9 0x1f4f072a +
        0x178dd499 0xb3268067 0x1dd39046 0x32ca79d9 +
        0xe46fd70e 0xeb92c7d3 0x2fd6de6f 0x86d4e1b7 

WRITEBLKIO  0x000006137d6fff40 +
        0x79b53007 0xdbd9cc64 0x90ac86ad 0x4e23d6a1 +
        0x5e428f79 0xf8e82eb6 0x2f110870 0x0a65eeaa +
        0x6a4ac5ae 0x68226d39 0x9a8c1ff7 0xa2719a91 +
        0x25b89959 0x3a7c48ec 0x5e46ff18 0xec18d8e2 

WRITEIO  0x000006197618ae80 4 0x2090baf5 

WRITEIO  0x00000619b6c92580 4 0xdb725b1b 

WRITEBLKIO  0x0000061275e79f00 +
        0xed60bc33 0x17b732ce 0xf0d475a3 0x8ea78f7a +
        0x279d15c8 0x43f1824a 0xd5c8f5e1 0xd25b0e1f +
        0x771cd7c4 0x9debe032 0xb6fc6146 0xa0b645ad +
        0xa57d4d4a 0x977cd6e5 0x143e1f15 0x591f954c 

WRITEBLK  0x00000012b1d1ab40 +
        0x3cf89539 0xc912b5ed 0x5607316c 0x2d458044 +
        0x87dfb52b 0x4ece795c 0x5d16ccf2 0x31612e58 +
        0x67a9e0a8 0xa25acae5 0xdc4ad418 0x32164618 +
        0xdb206b84 0xe81b49cd 0x8fbcf6b5 0xa7540ca1 

READIO  0x000006197618ae80 4 0x2090baf5 
WRITEBLKIO  0x0000061a5ffca2c0 +
        0x26c0c8b2 0x1fa7f069 0x688bf952 0x71dde61a +
        0xbbdc799c 0x906c1fc4 0xea6ced52 0x9e646747 +
        0xb5885589 0x37a73694 0x23e58ea7 0x8eef927e +
        0x85a021a5 0x7aa1229a 0xc8ed3bf2 0xef19547b 

READBLKIO  0x000006120d2cee40 +
        0x341a7b76 0x93e317b8 0xe3b3df3e 0x273216dc +
        0xceb5eb8d 0x87e761bb 0x057f29d2 0xf47bc6e1 +
        0xa3951c44 0x220ddf42 0xa8e0da5c 0x935fd754 +
        0x6ffa6abc 0x5518c955 0xd6eed9a1 0x481e5d99 

WRITEBLKIO  0x00000616ae9877c0 +
        0x67bd4829 0x677b6c7f 0x8af4c60a 0x30799896 +
        0x22b25156 0x78073414 0x8f940316 0x730bc382 +
        0x8a22bd45 0xbde159d4 0x89d29c48 0x1171c61b +
        0xd7270f02 0xa0aa2412 0xe7b10b1f 0x55a4ee4f 

READBLKIO  0x00000619e862b780 +
        0x9d3d28b0 0x4e8a906a 0x86a77ca6 0x1c52739c +
        0xeb510cfc 0x75d4f420 0xd5204475 0xdfdc2200 +
        0x577a6c19 0xb50fb2bf 0x9b4eff7f 0xb8b12104 +
        0xd883cfd2 0xaf7d5d00 0x82f2a564 0x2f303a15 

READBLKIO  0x00000606e7c90900 +
        0x539eec02 0x805b029c 0x0cabb5cf 0xa123d6e9 +
        0x53ba9a84 0x9051a82a 0xad1ef0a9 0x1f4f072a +
        0x178dd499 0xb3268067 0x1dd39046 0x32ca79d9 +
        0xe46fd70e 0xeb92c7d3 0x2fd6de6f 0x86d4e1b7 

WRITEBLKIO  0x0000061efeb0b480 +
        0x27c90666 0xb947f357 0x589fce3a 0xb8684837 +
        0x880a6a7b 0x8ba6a226 0xf53c5c29 0x828a71fd +
        0x7b8cad65 0x9d9d52c9 0x6d1c18e7 0xdb206a1d +
        0xd38000b2 0xb84a801f 0x2c5e2c15 0x527b5a0b 

WRITEMSKIO  0x0000060541b8a540 0x00ff  0x00000000 0x00000000 0x8de6ce21 0x13eaabad 

READBLK  0x00000012b1d1ab40 +
        0x3cf89539 0xc912b5ed 0x5607316c 0x2d458044 +
        0x87dfb52b 0x4ece795c 0x5d16ccf2 0x31612e58 +
        0x67a9e0a8 0xa25acae5 0xdc4ad418 0x32164618 +
        0xdb206b84 0xe81b49cd 0x8fbcf6b5 0xa7540ca1 

WRITEIO  0x0000060fdbec7c80 4 0x3c4fcc1d 

READIO  0x00000619b6c92580 4 0xdb725b1b 
WRITEBLKIO  0x0000061633a74200 +
        0x8fca77f8 0xf96987e8 0x8adbc16d 0xefdd049c +
        0x4be704e8 0xfe8e6fb4 0x16de1d60 0x1a883877 +
        0x202f396d 0xc0d97124 0xd0d3012b 0x2ce9da61 +
        0xa1f18b13 0x72da967b 0xc35f9c4d 0xc46b7294 

WRITEIO  0x0000060503533080 4 0xd274fb15 

WRITEMSKIO  0x000006046811b140 0xfff0  0xa374c226 0xace5b883 0x50a02dcc 0x00000000 

WRITEBLK  0x000000025ead9980 +
        0x584391f4 0x8138b8e4 0x821c84a6 0xbd227734 +
        0xfed326d2 0xb8087f35 0x4d7abc4b 0x1aa6a581 +
        0x5f55d1f3 0x7b782c2b 0x16f6da84 0xd7ba5672 +
        0xc8a9cf84 0x219e52be 0x406b079a 0xc2857287 

READIO  0x0000060fdbec7c80 4 0x3c4fcc1d 
READBLK  0x000000025ead9980 +
        0x584391f4 0x8138b8e4 0x821c84a6 0xbd227734 +
        0xfed326d2 0xb8087f35 0x4d7abc4b 0x1aa6a581 +
        0x5f55d1f3 0x7b782c2b 0x16f6da84 0xd7ba5672 +
        0xc8a9cf84 0x219e52be 0x406b079a 0xc2857287 

READMSKIO   0x0000060541b8a540 0x00ff  0x00000000 0x00000000 0x8de6ce21 0x13eaabad 

WRITEBLK  0x00000003c838ebc0 +
        0x96da0400 0xc8cf76d7 0xef48f0d9 0x0c194a02 +
        0xa8e52347 0x4d7efc9f 0x1781869f 0xf8f132fe +
        0xf70303b4 0x06c8b426 0x3f36e186 0xb5747dd5 +
        0xc27fea96 0x8f90ab6e 0x91b68b90 0x8f2d4326 

READIO  0x0000060503533080 4 0xd274fb15 
READMSKIO   0x000006046811b140 0xfff0  0xa374c226 0xace5b883 0x50a02dcc 0x00000000 

WRITEBLKIO  0x0000061d9068b400 +
        0x7806f830 0xeef6d5a8 0x797daf5f 0xf41d6773 +
        0xe775cf91 0xe6febf02 0x94c3be3e 0x8388feb2 +
        0xb56cddba 0x69e45d2f 0xdfc89e6b 0x28b1d8e1 +
        0x96905897 0xc1dfe904 0x8238e03a 0x29d7536f 

READBLK  0x00000003c838ebc0 +
        0x96da0400 0xc8cf76d7 0xef48f0d9 0x0c194a02 +
        0xa8e52347 0x4d7efc9f 0x1781869f 0xf8f132fe +
        0xf70303b4 0x06c8b426 0x3f36e186 0xb5747dd5 +
        0xc27fea96 0x8f90ab6e 0x91b68b90 0x8f2d4326 

WRITEMSKIO  0x00000607203801c0 0xff0f  0x6734e889 0x730c50fc 0x00000000 0xd2dfd4ac 

WRITEMSKIO  0x0000061cbdc2bf00 0x0000  0x00000000 0x00000000 0x00000000 0x00000000 


BA LABEL_0