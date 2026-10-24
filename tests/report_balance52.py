"""Summarize the measured 5.2 JSON; never run or alter simulations."""
from pathlib import Path
import json
import statistics

ROOT = Path(__file__).resolve().parents[1]


def main():
    data = json.loads((ROOT / 'docs/balanceamento_marco52.json').read_text())
    matches = data['matches']
    total = lambda key: sum(match[key] for match in matches)
    wins = sum(match['result'] == 'BOSS DEFEATED' for match in matches)
    losses = sum(match['result'] == 'GRUPO DERROTADO' for match in matches)
    lines = [
        '# Balanceamento — Marco 5.2', '',
        'Base exclusiva: Marco 5 aprovado, commit `b437d480c37b3834aa944b15c4e95385d567832d`. Godot 4.7.2 stable oficial, Linux. HP de Xardorok: 900. HP dos lacaios: 90 (antes 60); dano base: 14; limite simultâneo: 4; recarga de invocação: 3 turnos próprios.', '',
        'Foram executadas 36 partidas novas: 12 políticas × sementes 17, 42 e 99. Não foram alterados HP, recursos, iniciativa, RNG após a semente inicial, nem resultados para favorecer uma política. As decisões utilizam as APIs reais do combate. As políticas são deliberadamente simples e não equivalem à habilidade de um jogador humano.', '',
        f'Resultado: **{wins} vitórias e {losses} derrotas**, sem empate/limite e sem falhas de integridade. Duração: **{min(m["rounds"] for m in matches)}–{max(m["rounds"] for m in matches)} rodadas**; mediana {statistics.median(m["rounds"] for m in matches):.1f}. Processamento das simulações: {total("elapsed_ms") / 1000:.3f} s. Esse tempo não representa uma partida com animações.', '',
        '| Política | Vitórias | Derrotas | Rodadas | Invocados | Mortos | Movimentos | Lasers | Evasões | Defesas | Ações sacrificadas | Dano de meteoros |',
        '|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|',
    ]
    keys = ['minions_spawned', 'minions_defeated', 'minion_moves', 'minion_attacks', 'evades', 'guards', 'actions_sacrificed', 'meteor_damage']
    for policy in data['policies']:
        group = [m for m in matches if m['strategy'] == policy]
        counts = [str(sum(m[key] for m in group)) for key in keys]
        lines.append('| ' + ' | '.join([
            policy, str(sum(m['result'] == 'BOSS DEFEATED' for m in group)),
            str(sum(m['result'] == 'GRUPO DERROTADO' for m in group)),
            f'{min(m["rounds"] for m in group)}–{max(m["rounds"] for m in group)}', *counts,
        ]) + ' |')
    lines += [
        '', f'Totais: {total("minions_spawned")} lacaios invocados, {total("minions_defeated")} derrotados, {total("minion_moves")} movimentos, {total("minion_attacks")} lasers; {total("evades")} evasões, {total("guards")} defesas e {total("actions_sacrificed")} ações principais comprometidas. Meteoros causaram {total("meteor_damage")} de dano.', '',
        f'Xardorok executou {total("summons")} invocações, {total("smoke")} fumaças, {total("meteors")} conjurações de meteoros, {total("shield")} escudos e {total("aura")} auras. Conjurações principais são distintas dos impactos adicionais das reações do chefe, também registrados em meteor_impacts/meteor_damage.', '',
        'A política defensiva utilizou silêncio frequente e venceu suas três sementes, sem invocações: o impedimento mágico legítimo continua preservado. A invocação inicial obrigatória não ignora silêncio. As políticas focadas nos lacaios produziram novas invocações ao longo da batalha. A evasão excessiva comprometeu o poder ofensivo e não foi dominante. Mantiveram-se o dano das habilidades e os 900 HP de Xardorok; não se ajustaram números para fabricar uma taxa de vitória.', '',
        'Os números completos por partida, recursos, dano de aura/escudo/piso e conjurações estão em [balanceamento_marco52.json](balanceamento_marco52.json). actions_sacrificed conta decisões de evasão (cada uma compromete exatamente uma principal), mesmo se a batalha terminou antes de cobrar um débito futuro.', '',
        'Limitações: três sementes por política não constituem estudo estatístico de dificuldade. A IA de teste utiliza somente posições observadas/memorizadas. Validação da experiência e dificuldade por jogadores humanos continua necessária.',
    ]
    (ROOT / 'docs/BALANCEAMENTO_MARCO52.md').write_text('\n'.join(lines) + '\n')
    print(f'Marco 5.2: {len(matches)} partidas; {wins} vitórias; {losses} derrotas.')


if __name__ == '__main__':
    main()
