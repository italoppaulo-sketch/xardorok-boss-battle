# Balanceamento — Marco 5.2

Base exclusiva: Marco 5 aprovado, commit `b437d480c37b3834aa944b15c4e95385d567832d`. Godot 4.7.2 stable oficial, Linux. HP de Xardorok: 900. HP dos lacaios: 90 (antes 60); dano base: 14; limite simultâneo: 4; recarga de invocação: 3 turnos próprios.

Foram executadas 36 partidas novas: 12 políticas × sementes 17, 42 e 99. Não foram alterados HP, recursos, iniciativa, RNG após a semente inicial, nem resultados para favorecer uma política. As decisões utilizam as APIs reais do combate. As políticas são deliberadamente simples e não equivalem à habilidade de um jogador humano.

Resultado: **18 vitórias e 18 derrotas**, sem empate/limite e sem falhas de integridade. Duração: **5–25 rodadas**; mediana 8.0. Processamento das simulações: 6.424 s. Esse tempo não representa uma partida com animações.

| Política | Vitórias | Derrotas | Rodadas | Invocados | Mortos | Movimentos | Lasers | Evasões | Defesas | Ações sacrificadas | Dano de meteoros |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| agressivo | 3 | 0 | 6–6 | 12 | 4 | 15 | 25 | 0 | 18 | 0 | 508 |
| defensivo | 3 | 0 | 6–7 | 0 | 0 | 0 | 0 | 0 | 19 | 0 | 194 |
| cura | 0 | 3 | 13–15 | 12 | 3 | 59 | 98 | 53 | 0 | 53 | 210 |
| antimagia | 0 | 3 | 15–15 | 12 | 3 | 66 | 110 | 60 | 0 | 60 | 318 |
| lacaios | 0 | 3 | 18–25 | 42 | 34 | 61 | 93 | 77 | 0 | 77 | 787 |
| ignora_lacaios | 2 | 1 | 6–11 | 12 | 4 | 19 | 35 | 0 | 0 | 0 | 674 |
| mau_posicionamento | 1 | 2 | 5–6 | 6 | 2 | 16 | 24 | 0 | 0 | 0 | 468 |
| evita_meteoros | 3 | 0 | 8–9 | 12 | 3 | 27 | 45 | 21 | 15 | 21 | 249 |
| enfrenta_fumaca | 1 | 2 | 6–9 | 12 | 3 | 30 | 42 | 0 | 0 | 0 | 707 |
| evasao_excessiva | 0 | 3 | 12–14 | 12 | 3 | 61 | 83 | 53 | 0 | 53 | 576 |
| ignora_meteoros | 2 | 1 | 6–11 | 12 | 4 | 19 | 35 | 0 | 0 | 0 | 674 |
| corpo_a_corpo | 3 | 0 | 6–6 | 8 | 6 | 11 | 14 | 0 | 0 | 0 | 496 |

Totais: 152 lacaios invocados, 69 derrotados, 384 movimentos, 604 lasers; 264 evasões, 52 defesas e 264 ações principais comprometidas. Meteoros causaram 5861 de dano.

Xardorok executou 76 invocações, 73 fumaças, 30 conjurações de meteoros, 61 escudos e 82 auras. Conjurações principais são distintas dos impactos adicionais das reações do chefe, também registrados em meteor_impacts/meteor_damage.

A política defensiva utilizou silêncio frequente e venceu suas três sementes, sem invocações: o impedimento mágico legítimo continua preservado. A invocação inicial obrigatória não ignora silêncio. As políticas focadas nos lacaios produziram novas invocações ao longo da batalha. A evasão excessiva comprometeu o poder ofensivo e não foi dominante. Mantiveram-se o dano das habilidades e os 900 HP de Xardorok; não se ajustaram números para fabricar uma taxa de vitória.

Os números completos por partida, recursos, dano de aura/escudo/piso e conjurações estão em [balanceamento_marco52.json](balanceamento_marco52.json). actions_sacrificed conta decisões de evasão (cada uma compromete exatamente uma principal), mesmo se a batalha terminou antes de cobrar um débito futuro.

Limitações: três sementes por política não constituem estudo estatístico de dificuldade. A IA de teste utiliza somente posições observadas/memorizadas. Validação da experiência e dificuldade por jogadores humanos continua necessária.
