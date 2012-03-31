package net.akimirksnis.delta.game.gui.views
{
	public class LevelSelectionOverlay extends View
	{
		public static const view:XML =
			<view>
				<Overlay id="LevelSelectMenuOverlay" backgroundColor="0x222222">
					<Label left="20" top="20" color="0xEEEEEE" text="Pick a level:" />
					<List left="20" top="40" bottom="20" width="450" />
				</Overlay>
			</view>;
	}
}