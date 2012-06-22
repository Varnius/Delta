package net.akimirksnis.delta.game.gui.views
{
	public class LevelSelectionOverlay extends View
	{
		public static const view:XML =
			<view>
				<Overlay id="LevelSelectMenuOverlay" backgroundColor="0x222222">
					<VBox top="20" left="20" bottom="60" spacing="30">
						<HBox>
							<Label  color="0xEEEEEE" text="Nickname" />
							<InputText id="nickname" text="Varnius" />
						</HBox>
						<HBox spacing="30">
							<VBox>							
								<Label color="0xEEEEEE" text="Pick a level" />
								<List id="LevelList" width="400" height="400"/>
								<PushButton id="LoadButton" width="100" height="40" left="300" label="Create game" event="click:onCreateGameButtonClick" />
							</VBox>
							<VBox>
								<HBox>
									<Label color="0xEEEEEE" text="ServerID" />
									<InputText id="Nickname" />							
								</HBox>
								<PushButton id="Connect" width="150" height="40" label="Join game" event="click:onJoinGameButtonClick" />
							</VBox>
						</HBox>
					</VBox>
				</Overlay>
			</view>;
	}
}