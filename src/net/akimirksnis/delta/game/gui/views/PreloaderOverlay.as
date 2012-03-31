package net.akimirksnis.delta.game.gui.views
{
	public final class PreloaderOverlay extends View
	{
		public static const view:XML =
			<view>
				<Overlay id="preloader_overlay" backgroundColor="0x222222">
					<Label id="ProgressLabel" left="20" bottom="80" color="0xEEEEEE"/>
					<ProgressBar id="ProgressBar" height="50" left="20" right="20" bottom="20" />
				</Overlay>
			</view>;
	}
}