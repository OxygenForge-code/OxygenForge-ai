package com.geniskapi.alpha.oxygenforge.ai

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DividerDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberTopAppBarScrollState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.platform.LocalInspectionMode
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardActionHandler
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardOptions
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val APP_NAME = "OxygenForgeAI"

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            OxygenForgeApp()
        }
    }
}

private enum class Speaker {
    USER,
    ASSISTANT
}

private data class ChatMessage(
    val speaker: Speaker,
    val text: String,
)

@Composable
private fun OxygenForgeApp() {
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    val colors = if (dark) {
        darkColorScheme(
            primary = androidx.compose.ui.graphics.Color(0xFF8AB4F8),
            secondary = androidx.compose.ui.graphics.Color(0xFF8FD3C8),
            tertiary = androidx.compose.ui.graphics.Color(0xFFBCA7FF),
            surface = androidx.compose.ui.graphics.Color(0xFF111318),
            background = androidx.compose.ui.graphics.Color(0xFF0B0D10),
        )
    } else {
        lightColorScheme(
            primary = androidx.compose.ui.graphics.Color(0xFF2156D1),
            secondary = androidx.compose.ui.graphics.Color(0xFF006A60),
            tertiary = androidx.compose.ui.graphics.Color(0xFF6A55C9),
        )
    }

    MaterialTheme(colorScheme = colors, typography = MaterialTheme.typography) {
        Surface(modifier = Modifier.fillMaxSize()) {
            ChatScreen()
        }
    }
}

@OptIn(ExperimentalLayoutApi::class, ExperimentalMaterial3Api::class)
@Composable
private fun ChatScreen() {
    val scope = rememberCoroutineScope()
    val messages = remember {
        mutableStateListOf(
            ChatMessage(
                speaker = Speaker.ASSISTANT,
                text = "Selam Meriç. Ben OxygenForgeAI. Kod, fikir, özet, plan — ne yapacaksak beraber yaparız."
            )
        )
    }
    var input by rememberSaveable { mutableStateOf("") }
    val listState = rememberLazyListState()
    val suggestionPills = listOf(
        "Bir uygulama fikri ver",
        "Kod iskeleti oluştur",
        "Bu metni özetle",
        "Hata ayıkla"
    )

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.lastIndex)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(APP_NAME, fontWeight = FontWeight.SemiBold)
                        Text(
                            text = "Compose • Demo AI arayüzü",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarScrollState())
            )
        },
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    suggestionPills.forEach { suggestion ->
                        AssistChip(
                            onClick = { input = suggestion },
                            label = { Text(suggestion, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                        )
                    }
                }

                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Mesaj yaz...", maxLines = 1) },
                    minLines = 1,
                    maxLines = 5,
                    keyboardOptions = KeyboardOptions(
                        capitalization = KeyboardCapitalization.Sentences,
                        imeAction = ImeAction.Send
                    ),
                    trailingIcon = {
                        FilledIconButton(
                            onClick = {
                                val text = input.trim()
                                if (text.isNotEmpty()) {
                                    sendMessage(
                                        text = text,
                                        messages = messages,
                                        scope = scope,
                                        clearInput = { input = "" }
                                    )
                                }
                            }
                        ) {
                            Text("➤", fontSize = 18.sp)
                        }
                    }
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            HeroCard()
            HorizontalDivider(color = DividerDefaults.color)
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                state = listState
            ) {
                items(messages) { message ->
                    MessageBubble(message)
                }
            }
        }
    }
}

@Composable
private fun HeroCard() {
    ElevatedCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = "Hazır başlangıç proje",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = "Kotlin + Jetpack Compose + Material 3 tabanlı bir OxygenForgeAI iskeleti.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun MessageBubble(message: ChatMessage) {
    val isUser = message.speaker == Speaker.USER
    val alignment = if (isUser) Alignment.CenterEnd else Alignment.CenterStart
    val bubbleColor = if (isUser) {
        MaterialTheme.colorScheme.primaryContainer
    } else {
        MaterialTheme.colorScheme.secondaryContainer
    }
    val textColor = if (isUser) {
        MaterialTheme.colorScheme.onPrimaryContainer
    } else {
        MaterialTheme.colorScheme.onSecondaryContainer
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(0.88f),
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.cardColors(containerColor = bubbleColor)
        ) {
            Text(
                text = message.text,
                modifier = Modifier.padding(14.dp),
                color = textColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

private fun sendMessage(
    text: String,
    messages: MutableList<ChatMessage>,
    scope: kotlinx.coroutines.CoroutineScope,
    clearInput: () -> Unit,
) {
    messages.add(ChatMessage(Speaker.USER, text))
    clearInput()

    scope.launch {
        delay(650)
        messages.add(ChatMessage(Speaker.ASSISTANT, generateReply(text)))
    }
}

private fun generateReply(prompt: String): String {
    val lower = prompt.lowercase()
    return when {
        lower.contains("merhaba") || lower.contains("selam") -> "Selam! Bana hedefini söyle, sana yol haritası çıkarayım."
        lower.contains("kod") || lower.contains("android") -> "Tamamdır. Android tarafında önce temiz bir mimari kurarız, sonra ekranları tek tek ekleriz."
        lower.contains("özet") || lower.contains("ozet") -> "Kısa özet: ana fikir güçlü, ama önce çalışan bir iskelet kurmak en akıllıca hamle."
        lower.contains("hata") || lower.contains("error") -> "Hataları birlikte parçalayalım. Bana log'u at, hangi dosyada takıldığını bulalım."
        prompt.length < 18 -> "Bunu biraz açarsan daha net yardımcı olurum."
        else -> "Bunu not ettim: \"$prompt\". İstersen bundan bir proje planı, ekran taslağı ya da kod iskeleti çıkarayım."
    }
}
