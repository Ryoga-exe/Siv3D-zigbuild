# include <Siv3D.hpp>

void Main()
{
	Window::Resize(960, 540);
	const Font font{ 48 };

	while (System::Update())
	{
		font(U"Siv3D + Zig Build").drawAt(Scene::Center(), Palette::White);
	}
}
