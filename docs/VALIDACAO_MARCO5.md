# Validação — Marco 5

## Ambiente e evidência

Godot 4.7.2 é reutilizado do cache existente. O motor e as ferramentas de formatação não precisam ser baixados novamente. Testes de regras usam o mesmo código de produção; a apresentação consome eventos e não calcula dano independente.

## Resultados executados

Godot **4.7.2.stable.official.ed1daf0bf**, Linux, executável já disponível em cache. Importação headless do editor, execução inicial de 120 frames e todas as suítes abaixo terminaram com código zero e sem `ERROR:`.

| Suíte | Verificações | Falhas |
|---|---:|---:|
| Combate básico | 24 | 0 |
| Contratos de iniciativa/percepção/fase | 411 | 0 |
| Mecânicas e casos extremos do Marco 5 | 89 | 0 |
| Regressão do desaparecimento | 46 | 0 |
| Habilidades dos heróis e inimigos | 122 | 0 |
| Cena e HUD | 46 | 0 |
| Entradas reais de mouse/teclado | 28 | 0 |
| Cliques reais: evasão/defesa no HUD de meteoros | 11 | 0 |
| Assets e integração visual | 496 | 0 |
| Aura, eletricidade e vitória modular | 9 | 0 |
| **Total funcional** | **1.282** | **0** |

Além dessas verificações, **36 partidas completas** registraram **29 vitórias e 7 derrotas**, sem violações de integridade. O JSON final foi gerado após a inclusão da navegação de IA que evita fogo e do débito de ação de evasão fora do turno. Lotes anteriores usados durante integração não são os números da entrega.

A suíte gráfica `test_render_marco5.gd` foi executada com OpenGL/Mesa 25.2.8 llvmpipe: **7 cenários, 22 verificações, zero falhas e código de saída zero**, com capturas do viewport real 1200×700.

A partida completa `test_match_visual_marco5.gd`, política Antimagia e semente 17, foi executada na cena principal com apresentação dos eventos e terminou em **GRUPO DERROTADO na rodada 12**, zero falhas de execução e código de saída zero. HP, recursos e resultado não foram adulterados; a captura final documenta a derrota real. Esse ensaio gráfico é adicional às 36 partidas de balanceamento e não altera sua contagem.

## Escopo dos testes

- `test_battle.gd`: movimento comum, colisão, alcance, ações, condições de vitória/derrota e grupo inativo.
- `test_abilities.gd`: habilidades aprovadas dos cinco heróis, custos, alcances, danos, controles, cura, ilusão, voo, cadeia, lacaios e estados.
- `test_marco4.gd`: iniciativa individual, geometria, percepção, ocultação, transição e limite de reações. Expectativas revogadas de aura passiva e espera de meteoros foram substituídas pelos contratos do Marco 5.
- `test_marco5.gd`: invocação inicial/repetição após impedimento, escudo, recarga após expiração/dissipação, aura ativável, dano por evento, janela de meteoros, evasão com ação, defesa com bônus/PM, chão em fogo e expiração. Inclui bloqueio de ações comuns durante resposta, débito no próximo turno, congelamento, múltiplos ameaçados, fumaça, área parcialmente bloqueada, fim de rodada, mudança de fase, morte do chefe e desvio da IA por rota segura.
- `test_visibility_marco5.gd`: reprodução e regressão do desaparecimento investigado, mantendo a fumaça real.
- `test_scene.gd`, `test_input.gd`, `test_input_marco5.gd` e `test_visuals.gd`: integração, clique/teclado, recursos visuais e reinício.
- `test_encounters.gd`: 36 partidas com 12 políticas e 3 sementes, sem adulteração de resultados. Métricas completas em `balanceamento_marco5.json` e interpretação em `BALANCEAMENTO_MARCO5.md`.
- `test_render_marco5.gd`: capturas do viewport real da arena, escudo, aura, resposta de meteoro, fogo ambiental, descarga encadeada e vitória.

## Reprodução

```bash
python tests/run_tests.py --godot /caminho/para/Godot_v4.7.2-stable_linux.x86_64
python tests/report_balance.py
godot --path . --rendering-method gl_compatibility --script tests/test_render_marco5.gd
```

A última operação requer um display gráfico; headless não comprova a aparência dos efeitos. As cenas gráficas isoladas utilizam fixtures para alcançar interações específicas e são distintas das partidas de balanceamento.

## Custo de oportunidade e métricas

A evasão exige uma principal atualmente disponível. Quando usada fora do turno próprio, também reserva essa principal no próximo início de turno: o personagem não recebe uma ação ofensiva completa imediatamente após escapar. O débito vale uma vez; o turno subsequente volta ao orçamento normal. Movimento comum mantém seu custo em pontos de movimento. Defesa emergencial usa bônus e oito PM, e reduz somente o impacto.

No lote final houve 72 evasões e 72 ações sacrificadas, 27 defesas, 46 invocações, 47 fumaças, 57 escudos e 62 auras. Foram registradas 14 conjurações principais de Chuva de Meteoros; as 435 quedas incluem também meteoros das reações. Dano nominal de aura: 1.173; fogo no piso: 951. Na política defensiva, Silêncio pode impedir legitimamente a invocação enquanto durar o controle; a IA mantém a abertura pendente.

## Capturas reais

- [Arena e HUD](capturas/marco5_arena_hud.png)
- [Escudo de fogo](capturas/marco5_fire_shield.png)
- [Aura ativável](capturas/marco5_fire_aura.png)
- [Janela de resposta ao meteoro](capturas/marco5_meteoro_resposta.png)
- [Piso incendiado](capturas/marco5_piso_fogo.png)
- [Descarga encadeada](capturas/marco5_raio_encadeado.png)
- [Vitória cinematográfica](capturas/marco5_vitoria_cinematica.png)
- [Resultado da partida completa renderizada](capturas/marco5_partida_completa.png)

## Limitações

Windows e exportação executável não foram testados neste ambiente Linux. Três sementes por política são evidência exploratória, não garantia de dificuldade definitiva para jogadores humanos. A revisão artística e a experiência de controle permanecem sujeitas a testes manuais do usuário.
