extends SceneTree
## Guardião dos PNGs e SpriteFrames aprovados; hashes da branch Marco 5.
const APPROVED := {
	"assets/characters/cassandra/animations.tres":
	"00d2f825bf978c66829ee401f0cca8fe4a890f18b1cf68a8893cd7635198bbbb",
	"assets/characters/cassandra/atlas.png":
	"52d937b8c7831a59245441ac0c25c54c9c4d20daa55d6b0f90664ad916f316ac",
	"assets/characters/dalamud/animations.tres":
	"d5c6dfbef17077473ea8c85bfc5d12a1287049d34c040cd98d1abb2cdb8cd921",
	"assets/characters/dalamud/atlas.png":
	"976dc31d40bebfead5327a397ba385430bed9a99be8c96875e716fc5fb1aa593",
	"assets/characters/grosso/animations.tres":
	"20df34bf8f23c7a054e1796f880c47676cd302b84752fc2a4310f5200a7c8085",
	"assets/characters/grosso/atlas.png":
	"60c14f857c98f36f0f5d56db3f30d700247b4f85a3677b9f88150a1c22070d9b",
	"assets/characters/kodokami/animations.tres":
	"6e2fb5b0a4693d8d63394dea0746c9dea9e0534ce28b0d6e0b2555a16f1e9efe",
	"assets/characters/kodokami/atlas.png":
	"24cd39e99008f3c6f1fe14784e3660d359a736180178c4bfe4546b92a8f6a0e4",
	"assets/characters/lacaio/animations.tres":
	"cd6c911e2e4582b1b21a95af44bf08b8cfafbb8a3d45d77218c65dc5d7ea4237",
	"assets/characters/lacaio/atlas.png":
	"d8b79c6357cc3b2318917dd6f64d3e695b96ad9b3b85a48de64176cd8867ee90",
	"assets/characters/thomas/animations.tres":
	"d23905e32631727c2779ec5649ef19929307e2f514acc0d3de05dc2101c7852e",
	"assets/characters/thomas/atlas.png":
	"1371735f4912824fab040c516c77fd90e1a07efb0346aedc85be68aa2a17bcea",
	"assets/characters/thuxil/animations.tres":
	"a9119220db804c12d19dfb081cfde699fe53b3b14a9354db3b76fc8e34e98594",
	"assets/characters/thuxil/atlas.png":
	"29fefa205cb2c2d4ad66ca445a8004471b5490c168b595a23f24c00c2c9b3edc",
	"assets/characters/xardorok/animations.tres":
	"1d006e62cc4f9e1ea291b552ac9ff231a03315669efd71e41b8166ee7e81119b",
	"assets/characters/xardorok/atlas.png":
	"404b55ef151897c0d4bb817fa4dd15b56d0a834ccbf5c0e948cd25a5400e8540",
	"assets/characters/xardorok_marco4/animations.tres":
	"90bd5db654226c7fa542899aa210c0d6e8bbed5edbd890f0cf61525ffc8fe5fa",
	"assets/characters/xardorok_marco4/atlas.png":
	"ba16375742f673ef884177bee1e0022090f4107fa8636e806df0956ff14207b7"
}


func _initialize() -> void:
	var failures := 0
	for path in APPROVED:
		if FileAccess.get_sha256("res://" + path) != APPROVED[path]:
			failures += 1
			push_error("Recurso aprovado alterado: " + path)
	print("Marco5.1 recursos aprovados: %d verificações; %d falhas" % [APPROVED.size(), failures])
	quit(1 if failures else 0)
