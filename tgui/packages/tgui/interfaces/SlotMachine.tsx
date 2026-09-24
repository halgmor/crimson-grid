import { useEffect, useMemo, useRef, useState } from 'react';
import { Blink, Box, Button, Section, Stack } from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import { classes } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  symbols: SlotSymbol[];
  reels: Reel[];
  balance: number;
  working: number;
  winning: number;
  money: number;
  cost: number;
  plays: number;
  jackpots: number;
  jackpot: number;
  paymode: number;
  jackpot_id: string;
  trap_id: string;
  winning_line: number[]; // CRIMSON EDIT ADD - Slot machine
  winning_length: number; // CRIMSON EDIT ADD - Slot machine
  prizes: number[]; // CRIMSON EDIT ADD - Slot machine
};

type SlotSymbol = {
  id: string;
  icon_id: string;
  scale?: number; // CRIMSON EDIT ADD - Slot machine
  offset?: number; // CRIMSON EDIT ADD - Slot machine
};

type Reel = {
  symbols: string[];
};

const pluralS = (amount: number) => {
  return amount === 1 ? '' : 's';
};

const pickRandomMany = <T,>(items: T[], n: number) => {
  const result: T[] = [];
  for (let i = 0; i < n; i += 1) {
    result.push(pickRandom(items));
  }
  return result;
};

const pickRandom = <T,>(items: T[]) => {
  return items[Math.floor(Math.random() * items.length)];
};

export const SlotMachine = () => {
  const { act, data } = useBackend<Data>();
  const { symbols, cost, reels, balance } = data;
  const spinning = data.working === 1;

  const symbolsById = useMemo(() => {
    const map: Record<string, SlotSymbol> = {};
    for (const symbol of symbols) {
      map[symbol.id] = symbol;
    }
    return map;
  }, [symbols]);

  const jackpotSymbol = symbolsById[data.jackpot_id];
  const trapSymbol = data.trap_id ? symbolsById[data.trap_id] : null;

  return (
    <Window width={300} height={525}>
      {' '}
      {/* CRIMSON EDIT CHANGE - Slot machine - ORIGINAL: height={445} */}
      <Window.Content>
        <Banner />
        <Section>
          <div className={'SlotMachine__Reels'}>
            {reels.map((reel, i) => (
              <div key={i} className={'SlotMachine__Reel'}>
                <IconStrip
                  symbols={symbols}
                  symbolsById={symbolsById}
                  symbolsNeeded={reel.symbols}
                  spinning={spinning}
                  // CRIMSON EDIT ADD START - Slot machine
                  reelNumber={i + 1}
                  winningLine={data.winning_line}
                  winningLength={data.winning ? data.winning_length : 0}
                  // CRIMSON EDIT ADD END - Slot machine
                />
              </div>
            ))}
          </div>
        </Section>
        <Stack vertical fill>
          <Stack.Item>
            <Section fill align={'center'}>
              {/* CRIMSON EDIT CHANGE START - Slot machine - ORIGINAL: <Box inline textAlign={'center'} color="good" bold>Jackpot:</Box> */}
              <Box textAlign={'center'} color="good" bold>
                Jackpot: ${formatMoney(data.money + data.jackpot)}
              </Box>
              <Box textAlign={'center'} italic>
                Wins only count from first reel
              </Box>
              {data.prizes.map((prize, i) => (
                <Box key={i} textAlign={'center'}>
                  {i + 3} of a kind: ${prize}
                </Box>
              ))}
              <Box inline textAlign={'center'} color="good" bold>
                5
              </Box>
              {/* CRIMSON EDIT CHANGE END - Slot machine */}
              {jackpotSymbol && (
                <Box
                  className={classes([
                    'slotmachines32x32',
                    jackpotSymbol.icon_id,
                  ])}
                  style={{ verticalAlign: 'middle' }}
                />
              )}
              {/* CRIMSON EDIT ADD START - Slot machine */}
              <Box inline textAlign={'center'} color="good" bold>
                in a line: Jackpot
              </Box>
              {/* CRIMSON EDIT ADD END - Slot machine */}

              {trapSymbol && (
                <>
                  <Box inline color="bad" bold ml={5} mr={1}>
                    Trap:
                  </Box>
                  <Box
                    className={classes([
                      'slotmachines32x32',
                      trapSymbol.icon_id,
                    ])}
                    style={{ verticalAlign: 'middle' }}
                  />
                </>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow={1}>
            <Stack align={'stretch'}>
              <Stack.Item grow={1}>
                <Section
                  fill
                  title="Balance"
                  buttons={
                    <Button
                      onClick={() => act('payout')}
                      disabled={balance <= 0}
                    >
                      Refund
                    </Button>
                  }
                >
                  <Box textAlign={'center'} fontSize={2}>
                    {formatMoney(balance)} cr
                  </Box>
                </Section>
              </Stack.Item>
              <Stack.Item grow={1}>
                <Section fill>
                  <Button
                    fluid
                    textAlign={'center'}
                    fontSize={3}
                    color={'green'}
                    onClick={() => act('spin')}
                    disabled={spinning || balance < cost}
                  >
                    Spin!
                  </Button>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const getBannerPages = () => [
  BannerTitle,
  BannerOnlyFewCreds,
  // BannerPrizeMoney, // CRIMSON EDIT REMOVAL - Slot machine
  BannerTitle,
  BannerJackpot,
  BannerStats,
];

const BANNER_TEXTS = [
  'SPIN! SPIN!',
  'WARMED UP!',
  'HOT SLOTS',
  'SPIN & WIN!',
  'BELIEVE IT!',
  'ZERO 2 HERO!',
  'JUST ONE MORE',
  'SPIN OF FATE',
  'BONUS TIME!',
  'BORN TO SPIN!',
  'NICE SPIN!',
  'NO SPIN NO WIN',
  'BET & FORGET',
  'HONK 4 LUCK',
  'DEBT 4 LIFE',
  'SPINGULARITY',
  'SPIN CITY',
  'BURN & EARN',
  'JACKPOT SOON!',
  'WIN THE DAY!',
  'FORTUNE CALLS',
  'INSTANT GOLD!',
  'DREAM BIGGER!',
  'WINNERS ONLY!',
  'SPIN IS LIFE',
  'BIG ONE SOON!',
  'LUCKY SPIN!',
  'CASH OUT? NO!',
];

const WINNING_TEXTS = [
  null,
  'FREE SPINS!',
  'PRIZE!',
  'BIG PRIZE!',
  'JACKPOT!!!',
];

const Banner = () => {
  const { data } = useBackend<Data>();
  const [page, setPage] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setPage((page) => (page + 1) % getBannerPages().length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const winningText = WINNING_TEXTS[data.winning];
  if (winningText) {
    return (
      <Section className={'SlotMachine__Banner SlotMachine__Banner--winning'}>
        <BannerTitle text={winningText} />
      </Section>
    );
  }

  const Component = getBannerPages()[page];

  return (
    <Section className={'SlotMachine__Banner'}>
      <Component />
    </Section>
  );
};

type BannerTitleProps = {
  text?: string;
};

const BannerTitle = (props: BannerTitleProps) => {
  const { data } = useBackend<Data>();
  const defaultText = useRef(pickRandom(BANNER_TEXTS));
  let text = props.text;
  if (!text) {
    if (data.balance <= 0) {
      text = 'INSERT COIN';
    } else if (data.balance <= 5) {
      text = 'ONE LAST SPIN';
    } else {
      text = defaultText.current;
    }
  }
  const letters = text.split('');
  return (
    <div className={'SlotMachine__BannerTitle'}>
      {letters.map((letter, i) => (
        <span key={i}>{letter}</span>
      ))}
    </div>
  );
};

const BannerOnlyFewCreds = () => {
  const { data } = useBackend<Data>();
  const variant = useRef(pickRandom([0, 1]));

  if (variant.current === 1) {
    return (
      <div>
        For only{' '}
        <Blink interval={200} time={200}>
          <b>{data.cost}</b>
        </Blink>{' '}
        credit{pluralS(data.cost)}!
        <br />
        <Box inline fontSize={'12px'}>
          You can fix all your problems!
        </Box>
      </div>
    );
  }

  return (
    <div>
      Only{' '}
      <Blink interval={200} time={200}>
        <b>{data.cost}</b>
      </Blink>{' '}
      credit{pluralS(data.cost)} for a chance
      <br />
      to win <b>big</b>!
    </div>
  );
};

const BannerPrizeMoney = () => {
  const { data } = useBackend<Data>();
  return (
    <div>
      Available prize money:
      <br />
      <b>
        {data.money} credit{pluralS(data.money)}
      </b>
    </div>
  );
};

const BannerJackpot = () => {
  const { data } = useBackend<Data>();
  return (
    <div>
      Current jackpot:
      <br />
      <b>
        {data.money + data.jackpot} credit{pluralS(data.money + data.jackpot)}!
      </b>
    </div>
  );
};

const BannerStats = () => {
  const { data } = useBackend<Data>();
  return (
    <div>
      <Box inline fontSize={'13px'}>
        So far people have spun{' '}
        <b>
          {data.plays} time{pluralS(data.plays)}
        </b>
      </Box>
      <br />
      and won{' '}
      <b>
        {data.jackpots} jackpot{pluralS(data.jackpots)}!
      </b>
    </div>
  );
};

const ICON_STRIP_LENGTH = 30;

type IconStripProps = {
  symbols: SlotSymbol[];
  symbolsById: Record<string, SlotSymbol>;
  symbolsNeeded: string[];
  spinning?: boolean;
  // CRIMSON EDIT ADD START - Slot machine
  reelNumber: number;
  winningLine: number[];
  winningLength: number;
  // CRIMSON EDIT ADD END - Slot machine
};

const IconStrip = (props: IconStripProps) => {
  const {
    symbols,
    symbolsById,
    symbolsNeeded,
    spinning,
    reelNumber,
    winningLine,
    winningLength,
  } = props; // CRIMSON EDIT CHANGE - Slot machine - ORIGINAL: const { symbols, symbolsById, symbolsNeeded, spinning } = props;
  const symbolIds = useMemo(() => symbols.map((s) => s.id), [symbols]);

  const [drawnSymbols, setDrawnSymbols] = useState<string[]>([
    ...pickRandomMany(symbolIds, ICON_STRIP_LENGTH - 3),
    ...symbolsNeeded,
  ]);

  useEffect(() => {
    if (spinning) {
      setDrawnSymbols((drawn) => [
        ...drawn.slice(-3),
        ...pickRandomMany(symbolIds, ICON_STRIP_LENGTH - 6),
        ...symbolsNeeded,
      ]);
    } else {
      setDrawnSymbols([
        ...pickRandomMany(symbolIds, ICON_STRIP_LENGTH - 3),
        ...symbolsNeeded,
      ]);
    }
  }, [spinning]);

  return (
    <div
      className={classes([
        'SlotMachine__IconStrip',
        spinning && 'SlotMachine__IconStrip--spinning',
      ])}
    >
      {drawnSymbols.map((symbolId, i) => {
        const symbol = symbolsById[symbolId];
        // CRIMSON EDIT ADD START - Slot machine
        const row = i - (drawnSymbols.length - 3) + 1;
        const isWinningCell =
          !spinning &&
          reelNumber <= winningLength &&
          winningLine[reelNumber - 1] === row;
        // CRIMSON EDIT ADD END - Slot machine
        return (
          <div
            key={i}
            className={classes([
              'SlotMachine__Symbol',
              isWinningCell && 'SlotMachine__Symbol--winning',
            ])}
          >
            {/* CRIMSON EDIT CHANGE - Slot machine - ORIGINAL: <div key={i} className="SlotMachine__Symbol"> */}
            {symbol && (
              <Box
                className={classes(['slotmachines32x32', symbol.icon_id])}
                // CRIMSON EDIT ADD START - Slot machine
                style={
                  symbol.scale
                    ? {
                        transform: `scale(${symbol.scale}) translateY(${symbol.offset || 0}px)`,
                      }
                    : undefined
                }
                // CRIMSON EDIT ADD END - Slot machine
              />
            )}
          </div>
        );
      })}
    </div>
  );
};
