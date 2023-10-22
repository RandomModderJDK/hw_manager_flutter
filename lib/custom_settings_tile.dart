import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class HWMSettingsTile extends AbstractSettingsTile {
  HWMSettingsTile({
    this.leading,
    required this.title,
    this.description,
    this.onPressed,
    this.value,
    this.enabled = true,
    this.trailing,
    super.key,
  }) {
    onToggle = null;
    initialValue = false;
    activeSwitchColor = null;
    tileType = SettingsTileType.simpleTile;
  }

  late final SettingsTileType tileType;
  final Widget? leading;
  final Widget? title;
  final Widget? description;
  final Function(BuildContext context)? onPressed;
  late final Function(bool value)? onToggle;
  final Widget? value;
  late final bool initialValue;
  final bool enabled;
  late final Color? activeSwitchColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final TextScaler scaleFactor = MediaQuery.of(context).textScaler;

    final cantShowAnimation =
        tileType == SettingsTileType.switchTile ? onToggle == null && onPressed == null : onPressed == null;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cantShowAnimation
              ? null
              : () {
                  if (tileType == SettingsTileType.switchTile) {
                    onToggle?.call(!initialValue);
                  } else {
                    onPressed?.call(context);
                  }
                },
          highlightColor: theme.themeData.tileHighlightColor,
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 24),
                  child: IconTheme(
                    data: IconTheme.of(context).copyWith(
                      color: enabled ? theme.themeData.leadingIconsColor : theme.themeData.inactiveTitleColor,
                    ),
                    child: leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 24,
                    end: 24,
                    bottom: scaleFactor.scale(19),
                    top: scaleFactor.scale(19),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: TextStyle(
                          color: enabled ? theme.themeData.settingsTileTextColor : theme.themeData.inactiveTitleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        child: title ?? Container(),
                      ),
                      if (value != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? theme.themeData.tileDescriptionTextColor
                                  : theme.themeData.inactiveSubtitleColor,
                            ),
                            child: value!,
                          ),
                        )
                      else if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? theme.themeData.tileDescriptionTextColor
                                  : theme.themeData.inactiveSubtitleColor,
                            ),
                            child: description!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // if (tileType == SettingsTileType.switchTile)
              //   SizedBox(
              //     height: 30,
              //     child: VerticalDivider(),
              //   ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: trailing,
                )
              else if (tileType == SettingsTileType.switchTile)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                  child: Switch.adaptive(
                    value: initialValue,
                    onChanged: onToggle,
                    activeColor: enabled ? activeSwitchColor : theme.themeData.inactiveTitleColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
