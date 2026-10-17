# Balanceamento — Marco 4

## Execução

Executadas 27 partidas no 4.7.2-stable (official), com nove políticas e sementes 17, 42 e 99. O simulador não altera HP, recursos, iniciativa, recargas ou resultados. A aleatoriedade usa o RNG real do motor. As políticas conhecem apenas unidades percebidas e posições anteriormente observadas; nenhuma persegue a posição atual de inimigo oculto.

| Estratégia | Vitórias | Derrotas | Rodadas mín–máx | HP heróis ao fim, média | Dano chefe, média | Físicos | Meteoros | Fumaças | Invocações | Reações | Fase 2 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| agressivo | 3 | 0 | 5–6 | 409.7 | 196.3 | 0 | 4 | 2 | 0 | 21 | 3 |
| defensivo | 3 | 0 | 7–7 | 443.3 | 126.0 | 6 | 0 | 0 | 0 | 19 | 3 |
| cura | 3 | 0 | 5–5 | 477.0 | 40.0 | 0 | 3 | 2 | 0 | 20 | 3 |
| antimagia | 3 | 0 | 5–6 | 415.3 | 71.7 | 0 | 3 | 2 | 0 | 19 | 3 |
| lacaios | 3 | 0 | 5–5 | 401.0 | 66.0 | 0 | 3 | 2 | 0 | 19 | 3 |
| ignora_lacaios | 3 | 0 | 5–6 | 409.7 | 196.3 | 0 | 4 | 2 | 0 | 21 | 3 |
| mau_posicionamento | 3 | 0 | 5–5 | 206.0 | 238.7 | 0 | 1 | 3 | 3 | 21 | 3 |
| evita_meteoros | 3 | 0 | 5–6 | 415.3 | 71.7 | 0 | 3 | 2 | 0 | 19 | 3 |
| enfrenta_fumaca | 3 | 0 | 5–6 | 387.7 | 218.3 | 0 | 4 | 3 | 0 | 22 | 3 |

Resultado agregado: 27 vitórias, 0 derrotas, 0 partidas no limite de segurança. As colunas de habilidades e reações somam os três ensaios de cada estratégia. O JSON conserva rodadas, resultado, HP individual restante, dano por lacaios, ações e contagem completa de habilidades de cada partida.

## Como reproduzir

```bash
godot --path . --headless --script tests/test_encounters.gd
python tests/report_balance.py
```

Cada partida começa nas posições originais. Só o combatente ativo pode agir; inimigos usam a IA de produção. O limite é de 80 rodadas. Todas as operações verificam HP/PM, recursos não negativos, piso válido, ocupação e limite de lacaios. As políticas são agressiva, defensiva (controle/defesa), cura prioritária, Antimagia prioritária, foco em lacaios, ignorar lacaios, mau posicionamento (aproxima conjuradores), evasão de meteoros e enfrentamento da fumaça por área.

## Interpretação e limitações

Três sementes por política constituem uma comparação exploratória, não uma estimativa estatística para jogadores humanos. Estas heurísticas conhecem o catálogo e escolhem habilidades de dano elevadas; não representam um jogador descobrindo o jogo. Dano nominal é a soma dos eventos do motor e pode incluir excesso no golpe fatal. O dano ambiental e queimaduras contam para o chefe; o custo de HP da Fushigiri fica separado. Ações incluem bônus e ações principais registrados como conjuração; movimentos não contam.

As decisões do bot não foram alteradas para provocar derrotas nem os parâmetros modificados entre sementes. A estratégia defensiva utiliza Silêncio, suprimindo legitimamente magias e reações. O raio encadeado pode eliminar acólitos antes da entrada deles na iniciativa. Os testes funcionais isolados validam também magias que não aparecem nas partidas simuladas.

**Limitação de dificuldade:** todas as políticas testadas venceram. O ensaio demonstra que a batalha é vencível, mas não comprova dificuldade de chefe final nem punição suficiente de posicionamento ruim. Ajustes futuros devem ser validados com jogadores e novas sementes, mantendo estes resultados como evidência em vez de prometer balanceamento definitivo.
