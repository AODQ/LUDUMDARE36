module Entity.UI;
static import AOD;
static import Data;

class HUD : AOD.Entity {
public:
  this() {
    super();
    Set_Static_Pos(true);
    Set_Position(AOD.R_Window_Width-218/2, 235/2);
    Set_Sprite(Data.Image.HUD);
  }
  override void Update() {

  }
}
