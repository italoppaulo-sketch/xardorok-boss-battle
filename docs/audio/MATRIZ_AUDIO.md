# Matriz de cobertura sonora — Marco 6

Cada linha abaixo foi exercitada por uma chamada real ao motor, seguida pela apresentação de produção. Os nomes apontam para as entradas centralizadas de `assets/audio/catalog.json`; os arquivos correspondentes constam na segunda tabela. A matriz não altera o catálogo de habilidades.

| Personagem | Habilidade/API | Cues efetivamente disparados no teste |
| --- | --- | --- |
| Grosso | `basic` | `hammer_swing`, `hammer_hit` |
| Grosso | `double` | `hammer_swing`, `hammer_hit` |
| Grosso | `giant` | `giant` |
| Grosso | `hammer` | `ice_form` |
| Grosso | `skin` | `ice_form` |
| Kodokami | `basic` | `punch_air`, `punch` |
| Kodokami | `dodge` | `dodge` |
| Kodokami | `fushigiri` | `shadow_charge`, `sacrifice`, `sword_slash`, `shadow_rupture` |
| Kodokami | `unarmed` | `punch_air`, `punch` |
| Cassandra | `antispell` | `dispel`, `ui_confirm` |
| Cassandra | `basic` | `arcane_cast`, `arcane_hit` |
| Cassandra | `heal` | `arcane_cast`, `heal` |
| Cassandra | `purple_fire` | `violet_beam`, `arcane_hit` |
| Thomas | `basic` | `bow_release`, `arrow_hit` |
| Thomas | `energy_arrow` | `energy_charge`, `bow_release`, `energy_impact` |
| Thomas | `flight` | `flight` |
| Thomas | `ice_arrow` | `bow_release`, `ice_hit` |
| Thomas | `root_arrow` | `bow_release`, `arrow_hit`, `roots` |
| Thuxil | `basic` | `chain_charge`, `chain_jump` |
| Thuxil | `chain` | `chain_charge`, `chain_jump` |
| Thuxil | `illusion` | `illusion` |
| Thuxil | `silence` | `shadow_charge`, `silence` |
| Xardorok | `basic` | `hammer_swing`, `boss_hit` |
| Xardorok | `fire_aura` | `fire_ignite` |
| Xardorok | `fire_shield` | `fire_ignite` |
| Xardorok | `meteors` | `summon`, `warning` |
| Xardorok | `smoke` | `smoke` |
| Xardorok | `summon` | `summon`, `minion_spawn` |
| Acólito | `basic` | `punch_air`, `body_hit` |
| Acólito | `red_laser` | `laser_charge`, `laser_emit`, `laser_hit` |

## Estados e eventos

| Evento | Cues / ligação |
| --- | --- |
| Ataque duplo / desarmado duplo | Dois contatos reais separados por 0,4 s; `hammer_hit` / `punch` |
| Martelo encantado | `hammer_hit` no contato físico; `ice_hit` no dano extra de gelo |
| Fushigiri | `shadow_charge` na preparação; `sword_slash` e `shadow_rupture` no contato; `sacrifice` discreto no custo de HP |
| Saltos de raio | `chain_jump` por evento link, em intervalos de 0,12 s; carga não reinicia |
| Congelamento / enraizamento / silêncio | `ice_shards` / `roots` / `silence` nos estados |
| Queimadura / piso / aura / retaliação | Família `fire_hit`; ignição `fire_ignite`; presença de aura enquanto visualmente ativa |
| Demais buffs | Família de gelo, esquiva, duplicata, voo e acento arcano; aplicação e expiração seguem os eventos reais |
| Expiração / dissipação | Confirmação discreta; `land` ao terminar voo; antimagia usa `dispel` |
| Invocação | `summon` ao conjurar e `minion_spawn` para surgimento |
| Laser | `laser_charge`, emissão no cronograma visual e `laser_hit` no contato |
| Morte do acólito | `minion_death` no HP visual zero; `minion_dissolve` na retirada do nó após 0,65 s |
| Movimento | `step` quando a rota visual alcança uma célula; voo usa família aérea |
| Janela de meteoro | Aviso `warning` ao surgirem marcas; interface discreta; nenhuma iniciativa adicional |
| Meteoro | Conjuração, aviso, `meteor_fall` na queda e `meteor_hit` exatamente 0,3 s depois; fogo no evento world |
| Defender / evadir / não reagir | `guard` / deslocamento `dodge` / impacto normal; `guard_hit` no contato parcialmente bloqueado |
| Fase 2 | Cue `phase` no evento de apresentação; crossfade alinhado para `phase_two` |
| Crítico / esquiva / dano | `critical` / `dodge` / contato da família da habilidade; dano não adiciona impactos genéricos duplicados |
| Interface | `ui_select`, `ui_confirm`, `ui_invalid`, `ui_open`; volumes no bus UI |
| Herói derrotado | `hero_death`; derrota do grupo usa música `defeat` depois da apresentação final |
| Vitória | Ataque final termina, música perde intensidade, ressonância de queda; `crown` em 1,00 s; fanfarra `victory` no título em 1,05 s |
| Pular / reiniciar | Pular cessa fanfarra e vozes; reiniciar limpa sons e reinicia música/ambiente, preservando volumes |
| Dalamud | Família etérea `illusion` no evento spirit já existente; sem novo combatente ou mudança de identidade |

## Recursos e roteamento

| Cue | Arquivo | Bus |
| --- | --- | --- |
| `hammer_swing` | `res://assets/audio/sfx/heroes/hammer_swing.wav` | SFX |
| `hammer_hit` | `res://assets/audio/sfx/heroes/hammer_hit.wav` | SFX |
| `ice_form` | `res://assets/audio/sfx/heroes/ice_form.wav` | SFX |
| `ice_shards` | `res://assets/audio/sfx/heroes/ice_shards.wav` | SFX |
| `giant` | `res://assets/audio/sfx/heroes/giant.wav` | SFX |
| `punch` | `res://assets/audio/sfx/heroes/punch.wav` | SFX |
| `dodge` | `res://assets/audio/sfx/heroes/dodge.wav` | SFX |
| `shadow_charge` | `res://assets/audio/sfx/heroes/shadow_charge.wav` | SFX |
| `sword_slash` | `res://assets/audio/sfx/heroes/sword_slash.wav` | SFX |
| `shadow_rupture` | `res://assets/audio/sfx/heroes/shadow_rupture.wav` | SFX |
| `sacrifice` | `res://assets/audio/sfx/heroes/sacrifice.wav` | SFX |
| `bow_release` | `res://assets/audio/sfx/heroes/bow_release.wav` | SFX |
| `arrow_hit` | `res://assets/audio/sfx/heroes/arrow_hit.wav` | SFX |
| `roots` | `res://assets/audio/sfx/heroes/roots.wav` | SFX |
| `energy_charge` | `res://assets/audio/sfx/heroes/energy_charge.wav` | SFX |
| `energy_impact` | `res://assets/audio/sfx/heroes/energy_impact.wav` | SFX |
| `flight` | `res://assets/audio/sfx/heroes/flight.wav` | SFX |
| `arcane_cast` | `res://assets/audio/sfx/heroes/arcane_cast.wav` | SFX |
| `arcane_hit` | `res://assets/audio/sfx/heroes/arcane_hit.wav` | SFX |
| `dispel` | `res://assets/audio/sfx/heroes/dispel.wav` | SFX |
| `heal` | `res://assets/audio/sfx/heroes/heal.wav` | SFX |
| `violet_beam` | `res://assets/audio/sfx/heroes/violet_beam.wav` | SFX |
| `illusion` | `res://assets/audio/sfx/heroes/illusion.wav` | SFX |
| `silence` | `res://assets/audio/sfx/heroes/silence.wav` | SFX |
| `boss_hit` | `res://assets/audio/sfx/boss/boss_hit.wav` | SFX |
| `smoke` | `res://assets/audio/sfx/boss/smoke.wav` | SFX |
| `summon` | `res://assets/audio/sfx/boss/summon.wav` | SFX |
| `fire_ignite` | `res://assets/audio/sfx/boss/fire_ignite.wav` | SFX |
| `fire_hit` | `res://assets/audio/sfx/boss/fire_hit.wav` | SFX |
| `phase` | `res://assets/audio/sfx/boss/phase.wav` | SFX |
| `crown` | `res://assets/audio/sfx/boss/crown.wav` | SFX |
| `minion_spawn` | `res://assets/audio/sfx/minions/minion_spawn.wav` | SFX |
| `minion_death` | `res://assets/audio/sfx/minions/minion_death.wav` | SFX |
| `footsteps` | `res://assets/audio/sfx/combat/footsteps.wav` | SFX |
| `body_hit` | `res://assets/audio/sfx/combat/body_hit.wav` | SFX |
| `hero_death` | `res://assets/audio/sfx/combat/hero_death.wav` | SFX |
| `critical` | `res://assets/audio/sfx/combat/critical.wav` | SFX |
| `ui` | `res://assets/audio/sfx/ui/ui.wav` | UI |
| `ui_select` | `res://assets/audio/sfx/ui/ui_select.wav` | UI |
| `ui_confirm` | `res://assets/audio/sfx/ui/ui_confirm.wav` | UI |
| `ui_invalid` | `res://assets/audio/sfx/ui/ui_invalid.wav` | UI |
| `ui_open` | `res://assets/audio/sfx/ui/ui_open.wav` | UI |
| `step` | `res://assets/audio/sfx/combat/step.wav` | SFX |
| `land` | `res://assets/audio/sfx/combat/land.wav` | SFX |
| `punch_air` | `res://assets/audio/sfx/heroes/punch_air.wav` | SFX |
| `ice_hit` | `res://assets/audio/sfx/heroes/ice_hit.wav` | SFX |
| `minion_dissolve` | `res://assets/audio/sfx/minions/minion_dissolve.wav` | SFX |
| `chain_charge` | `res://assets/audio/sfx/heroes/chain_charge.wav` | SFX |
| `chain_jump` | `res://assets/audio/sfx/heroes/chain_jump.wav` | SFX |
| `laser_charge` | `res://assets/audio/sfx/minions/laser_charge.wav` | SFX |
| `laser_emit` | `res://assets/audio/sfx/minions/laser_emit.wav` | SFX |
| `laser_hit` | `res://assets/audio/sfx/minions/laser_hit.wav` | SFX |
| `meteor_fall` | `res://assets/audio/sfx/boss/meteor_fall.wav` | SFX |
| `meteor_hit` | `res://assets/audio/sfx/boss/meteor_hit.wav` | SFX |
| `guard` | `res://assets/audio/sfx/combat/guard.wav` | SFX |
| `guard_hit` | `res://assets/audio/sfx/combat/guard_hit.wav` | SFX |
| `warning` | `res://assets/audio/sfx/ui/warning.wav` | UI |
| `battle` | `res://assets/audio/music/battle.ogg` | Music |
| `phase_two` | `res://assets/audio/music/phase_two.ogg` | Music |
| `victory` | `res://assets/audio/music/victory.ogg` | Music |
| `defeat` | `res://assets/audio/music/defeat.ogg` | Music |
| `ruins` | `res://assets/audio/ambience/ruins.ogg` | Ambience |
| `aura_presence` | `res://assets/audio/ambience/aura_presence.ogg` | Ambience |

## Estados individualizados

| Estado | Aplicação | Arquivo | Expiração |
| --- | --- | --- | --- |
| `burning` | `fire_hit` | `res://assets/audio/sfx/boss/fire_hit.wav` | `ui_confirm` |
| `frozen` | `ice_shards` | `res://assets/audio/sfx/heroes/ice_shards.wav` | `ui_confirm` |
| `rooted` | `roots` | `res://assets/audio/sfx/heroes/roots.wav` | `ui_confirm` |
| `silenced` | `silence` | `res://assets/audio/sfx/heroes/silence.wav` | `ui_confirm` |
| `defense` | `ice_form` | `res://assets/audio/sfx/heroes/ice_form.wav` | `ui_confirm` |
| `attack` | `critical` | `res://assets/audio/sfx/combat/critical.wav` | `ui_confirm` |
| `evasion` | `dodge` | `res://assets/audio/sfx/heroes/dodge.wav` | `ui_confirm` |
| `illusion` | `illusion` | `res://assets/audio/sfx/heroes/illusion.wav` | `ui_confirm` |
| `flight` | `flight` | `res://assets/audio/sfx/heroes/flight.wav` | `land` |
| `ice_skin` | `ice_form` | `res://assets/audio/sfx/heroes/ice_form.wav` | `ui_confirm` |
| `ice_hammer` | `ice_form` | `res://assets/audio/sfx/heroes/ice_form.wav` | `ui_confirm` |
| `giant` | `giant` | `res://assets/audio/sfx/heroes/giant.wav` | `ui_confirm` |
| `fire_shield` | `fire_ignite` | `res://assets/audio/sfx/boss/fire_ignite.wav` | `ui_confirm` |
| `fire_aura` | `fire_ignite` | `res://assets/audio/sfx/boss/fire_ignite.wav` | `ui_confirm` |

Buffs pessoais usam o cue de conjuração e suprimem a duplicação no evento de estado do mesmo conjurador. O caso `defense` da Pele Glacial não reproduz uma segunda cristalização.
